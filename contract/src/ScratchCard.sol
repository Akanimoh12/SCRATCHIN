// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

interface IPrizePool {
    function recordDeposit(uint256 amount) external;
    function paySmallWin(address winner, uint256 amount) external;
    function payJackpot(address winner) external returns (uint256 amount);
    function reserve() external view returns (uint256);
    function jackpot() external view returns (uint256);
}

interface IReferral {
    function registerReferral(address buyer, address referrer) external;
    function creditReward(address buyer, uint256 amount) external;
    function referrerOf(address buyer) external view returns (address);
}

/// @notice SCRATCHIN' ERC-721 scratch card game.
///
/// Flow:
///   1. Player approves USDC, calls buyCards(qty, referrer).
///   2. USDC is split: 5% → Referral (if referrer set), 95% → PrizePool.
///   3. After revealDelay blocks, player or Reactive RSC calls revealCard(tokenId).
///   4. Block hash seeds 3 symbols. 3-match = jackpot, 2-match = small win.
///   5. If card is not revealed within EXPIRY_BLOCKS, owner can call refundCard for a full USDC refund.
///
/// Leaderboard:
///   - totalWins / totalWinnings / cardsBought tracked per address.
///   - winsThisWeek tracked lazily: on any win, if 7+ days have passed since weekStart, counters reset.
///   - Recent 20 winners stored in a ring buffer.
///
/// Token enumeration:
///   - tokensByOwner[addr] returns all tokenIds ever minted to that address.
///   - This is append-only (NFT transfers do NOT update the list — use ownerOf for current owner).
contract ScratchCard is ERC721, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ─── Constants ────────────────────────────────────────────────────────────

    /// USDC has 6 decimals. 0.5 USDC = 500_000.
    uint256 public constant CARD_PRICE_DEFAULT = 500_000;
    /// 5% referral cut in basis points.
    uint256 public constant REFERRAL_BPS = 500;
    /// Cards not revealed within this many blocks can be refunded.
    uint256 public constant EXPIRY_BLOCKS = 250;

    // ─── Types ────────────────────────────────────────────────────────────────

    enum CardState { Pending, Scratched, Refunded }

    // Symbol index 0-4 maps to: Gem, Star, Bell, Zap, Circle
    struct Card {
        address      mintedTo;      // original minter (for refund auth + leaderboard)
        uint256      purchaseBlock;
        uint256      pricePaid;     // USDC amount paid for this card (for refund)
        CardState    state;
        uint8[3]     symbols;       // filled on reveal; 0 before
        uint256      prize;         // USDC won (filled on reveal)
        bytes32      seedHash;      // entropy captured at purchase (blockhash of prior block)
    }

    // ─── State ────────────────────────────────────────────────────────────────

    IERC20     public immutable usdc;
    IPrizePool public prizePool;
    IReferral  public referral;
    address    public reactiveRevealer;

    uint256 public cardPrice    = CARD_PRICE_DEFAULT;   // USDC (6 dec)
    uint256 public revealDelay  = 3;                    // blocks
    uint256 public smallWinAmount = 250_000;            // 0.25 USDC

    uint256 private _nextTokenId = 1;

    mapping(uint256 => Card)   public cards;
    mapping(address => uint256[]) private _tokensByOwner; // append-only mint history

    // ─── Leaderboard ──────────────────────────────────────────────────────────

    mapping(address => uint256) public totalWins;
    mapping(address => uint256) public totalWinnings;
    mapping(address => uint256) public cardsBought;

    // Weekly wins: tracked lazily. weekOf[addr] = timestamp of their last week-start.
    mapping(address => uint256) public winsThisWeek;
    mapping(address => uint256) public weekOf; // timestamp of the week this player's count is in
    uint256 public globalWeekStart;

    // Recent winners ring buffer — last 20 wins globally
    address[20] public recentWinners;
    uint256[20] public recentPrizes;
    uint256[20] public recentTimestamps;
    uint256     public recentIndex;

    // ─── Events ───────────────────────────────────────────────────────────────

    event CardPurchased(address indexed buyer, uint256 indexed tokenId, uint256 indexed purchaseBlock);
    event CardRevealed(uint256 indexed tokenId, address indexed winner, uint8 s0, uint8 s1, uint8 s2, uint256 prize);
    event CardRefunded(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event WeekReset(uint256 newWeekStart);

    // ─── Errors ───────────────────────────────────────────────────────────────

    error ZeroQuantity();
    error InsufficientAllowance();
    error NotScratchable();
    error AlreadyScratched();
    error Unauthorized();
    error BlockHashUnavailable();
    error NotExpired();
    error NotRefundable();

    // ─── Constructor ──────────────────────────────────────────────────────────

    constructor(address _usdc, address _owner, address _prizePool, address _referral)
        ERC721("SCRATCHIN Card", "SCRATCH")
        Ownable(_owner)
    {
        usdc       = IERC20(_usdc);
        prizePool  = IPrizePool(_prizePool);
        referral   = IReferral(_referral);
        globalWeekStart = block.timestamp;
    }

    // ─── Admin ────────────────────────────────────────────────────────────────

    function setCardPrice(uint256 _price)       external onlyOwner { cardPrice = _price; }
    function setRevealDelay(uint256 _delay)     external onlyOwner { revealDelay = _delay; }
    function setSmallWinAmount(uint256 _amount) external onlyOwner { smallWinAmount = _amount; }
    function setReactiveRevealer(address _r)    external onlyOwner { reactiveRevealer = _r; }
    function setPrizePool(address _p)           external onlyOwner { prizePool = IPrizePool(_p); }
    function setReferral(address _r)            external onlyOwner { referral = IReferral(_r); }

    // ─── Buy ──────────────────────────────────────────────────────────────────

    /// @notice Buy `quantity` scratch cards. Player must have approved USDC.
    /// @param quantity Number of cards to buy (1–50).
    /// @param referrer Referrer wallet address, or address(0) for none.
    function buyCards(uint256 quantity, address referrer) external nonReentrant {
        if (quantity == 0) revert ZeroQuantity();
        uint256 totalCost = cardPrice * quantity;

        // Pull USDC from buyer
        usdc.safeTransferFrom(msg.sender, address(this), totalCost);

        // Register referral on first-ever purchase
        if (referrer != address(0) && referrer != msg.sender
            && referral.referrerOf(msg.sender) == address(0))
        {
            referral.registerReferral(msg.sender, referrer);
        }

        // Split: 5% referral cut (if referrer exists), rest to prize pool
        uint256 referralCut = 0;
        address ref = referral.referrerOf(msg.sender);
        if (ref != address(0)) {
            referralCut = (totalCost * REFERRAL_BPS) / 10000;
        }
        uint256 poolAmount = totalCost - referralCut;

        // Transfer pool amount to PrizePool and record
        usdc.safeTransfer(address(prizePool), poolAmount);
        prizePool.recordDeposit(poolAmount);

        // Transfer referral cut to Referral contract and credit
        if (referralCut > 0) {
            usdc.safeTransfer(address(referral), referralCut);
            referral.creditReward(msg.sender, referralCut);
        }

        cardsBought[msg.sender] += quantity;

        // Mint cards
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _nextTokenId++;
            _mint(msg.sender, tokenId);
            cards[tokenId] = Card({
                mintedTo:      msg.sender,
                purchaseBlock: block.number,
                pricePaid:     cardPrice,
                state:         CardState.Pending,
                symbols:       [uint8(0), uint8(0), uint8(0)],
                prize:         0,
                // Capture entropy from the previous block's hash at purchase time.
                // It is already finalized (so always available later, no 256-block
                // race with the Reactive callback) yet unknown when the buyer
                // submitted their tx, so it cannot be gamed.
                seedHash:      blockhash(block.number - 1)
            });
            _tokensByOwner[msg.sender].push(tokenId);
            emit CardPurchased(msg.sender, tokenId, block.number);
        }
    }

    // ─── Reveal ───────────────────────────────────────────────────────────────

    /// @notice Reveal a card. Callable directly by the current NFT owner.
    function revealCard(uint256 tokenId) external nonReentrant {
        _reveal(tokenId, msg.sender);
    }

    /// @notice Reactive Network callback entry point.
    /// @dev The Reactive Callback Proxy executes this and injects `rvm_id` as the
    ///      first argument. Authorization is on `msg.sender` (the proxy address),
    ///      which must equal `reactiveRevealer`. The `rvm_id` arg is unused here
    ///      but is part of the mandatory Reactive callback signature.
    function revealCardCallback(address /* rvm_id */, uint256 tokenId) external nonReentrant {
        if (msg.sender != reactiveRevealer) revert Unauthorized();
        // The reactive revealer is pre-authorized; pass it through as the caller so
        // the shared authorization check below succeeds for the callback path.
        _reveal(tokenId, reactiveRevealer);
    }

    /// @notice Shared reveal logic for both the owner path and the Reactive callback.
    /// @param caller The authenticated msg.sender of the entry point (owner or revealer).
    function _reveal(uint256 tokenId, address caller) internal {
        Card storage card = cards[tokenId];
        // State checks first so refunded/scratched cards return a clear error even
        // though the NFT may have been burned (which would make ownerOf revert).
        if (card.state == CardState.Scratched) revert AlreadyScratched();
        if (card.state == CardState.Refunded)  revert NotRefundable();

        address currentOwner = ownerOf(tokenId); // authoritative ERC-721 owner
        if (caller != currentOwner && caller != reactiveRevealer) revert Unauthorized();
        if (block.number < card.purchaseBlock + revealDelay) revert NotScratchable();

        // Entropy was captured at purchase (card.seedHash), so the reveal works no
        // matter how long the cross-chain Reactive callback takes — no 256-block
        // blockhash window to race against.
        bytes32 bhash = card.seedHash;
        if (bhash == bytes32(0)) revert BlockHashUnavailable();

        bytes32 seed = keccak256(abi.encodePacked(bhash, tokenId, card.mintedTo, card.purchaseBlock));

        uint8 s0 = uint8(uint8(seed[0]) % 5);
        uint8 s1 = uint8(uint8(seed[1]) % 5);
        uint8 s2 = uint8(uint8(seed[2]) % 5);

        card.symbols = [s0, s1, s2];
        card.state   = CardState.Scratched;

        uint256 prize = 0;
        if (s0 == s1 && s1 == s2) {
            // Jackpot: 3-of-3
            prize = prizePool.jackpot();
            if (prize > 0) {
                prize = prizePool.payJackpot(currentOwner);
            }
        } else if (s0 == s1 || s1 == s2 || s0 == s2) {
            // Small win: 2-of-3
            uint256 avail = prizePool.reserve();
            if (avail >= smallWinAmount) {
                prize = smallWinAmount;
                prizePool.paySmallWin(currentOwner, prize);
            }
        }

        card.prize = prize;
        if (prize > 0) _recordWin(currentOwner, prize);

        emit CardRevealed(tokenId, currentOwner, s0, s1, s2, prize);
    }

    // ─── Refund ───────────────────────────────────────────────────────────────

    /// @notice Refund a card that was never revealed within EXPIRY_BLOCKS.
    /// Only the current NFT owner can claim. Card is burned. Full card price returned from reserve.
    function refundCard(uint256 tokenId) external nonReentrant {
        Card storage card = cards[tokenId];
        if (card.state != CardState.Pending) revert NotRefundable();
        if (block.number < card.purchaseBlock + EXPIRY_BLOCKS) revert NotExpired();

        address currentOwner = ownerOf(tokenId);
        if (msg.sender != currentOwner) revert Unauthorized();

        card.state = CardState.Refunded;
        _burn(tokenId);

        // Refund exactly card.pricePaid from reserve.
        // Reserve should always cover this (10% of every deposit builds it up),
        // but if somehow reserve is short, refund whatever is available — never touch the jackpot.
        uint256 refundAmt = card.pricePaid;
        uint256 avail = prizePool.reserve();
        uint256 payout = avail >= refundAmt ? refundAmt : avail;
        if (payout > 0) {
            prizePool.paySmallWin(currentOwner, payout);
        }

        emit CardRefunded(tokenId, currentOwner, payout);
    }

    // ─── Views ────────────────────────────────────────────────────────────────

    function isScratchable(uint256 tokenId) external view returns (bool) {
        Card storage card = cards[tokenId];
        return card.state == CardState.Pending
            && block.number >= card.purchaseBlock + revealDelay
            && block.number <  card.purchaseBlock + EXPIRY_BLOCKS;
    }

    function isExpired(uint256 tokenId) external view returns (bool) {
        Card storage card = cards[tokenId];
        return card.state == CardState.Pending
            && block.number >= card.purchaseBlock + EXPIRY_BLOCKS;
    }

    function getCard(uint256 tokenId) external view returns (Card memory) {
        return cards[tokenId];
    }

    /// @notice Returns all tokenIds minted to `addr` (append-only; includes transferred-away cards).
    function getTokensByOwner(address addr) external view returns (uint256[] memory) {
        return _tokensByOwner[addr];
    }

    function getRecentWinners() external view returns (
        address[20] memory winners,
        uint256[20] memory prizes,
        uint256[20] memory timestamps
    ) {
        return (recentWinners, recentPrizes, recentTimestamps);
    }

    // ─── Leaderboard ──────────────────────────────────────────────────────────

    function _recordWin(address winner, uint256 amount) internal {
        totalWins[winner]++;
        totalWinnings[winner] += amount;

        // Lazy weekly reset: if 7+ days have elapsed globally, reset global counter and player's week
        if (block.timestamp >= globalWeekStart + 7 days) {
            globalWeekStart = block.timestamp;
            emit WeekReset(globalWeekStart);
        }

        // Lazy per-player weekly reset
        if (weekOf[winner] < globalWeekStart) {
            winsThisWeek[winner] = 0;
            weekOf[winner] = globalWeekStart;
        }
        winsThisWeek[winner]++;

        // Ring buffer
        uint256 idx = recentIndex % 20;
        recentWinners[idx]    = winner;
        recentPrizes[idx]     = amount;
        recentTimestamps[idx] = block.timestamp;
        recentIndex++;
    }

    /// @notice Owner can force a weekly leaderboard reset.
    function resetWeeklyLeaderboard() external onlyOwner {
        globalWeekStart = block.timestamp;
        emit WeekReset(globalWeekStart);
    }
}
