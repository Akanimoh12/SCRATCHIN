// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice On-chain referral system for SCRATCHIN'.
/// - One referrer per buyer, set immutably on first card purchase.
/// - 5% of each card purchase (in USDC) is credited to the referrer.
/// - Referrers can claim their accumulated USDC rewards at any time.
/// - 10+ referred active buyers → "Hustler" badge on-chain.
contract Referral is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable usdc;
    address public scratchCard;

    uint256 public constant HUSTLER_THRESHOLD = 10;

    mapping(address => address) public referrerOf;       // buyer  => referrer
    mapping(address => uint256) public referralCount;    // referrer => # referred buyers
    mapping(address => uint256) public pendingRewards;   // referrer => claimable USDC (6 dec)
    mapping(address => uint256) public totalEarned;      // referrer => lifetime USDC earned

    event ReferralRegistered(address indexed referrer, address indexed buyer);
    event ReferralEarned(address indexed referrer, address indexed buyer, uint256 usdcAmount);
    event RewardsClaimed(address indexed referrer, uint256 usdcAmount);

    error Unauthorized();
    error AlreadyReferred();
    error SelfReferral();
    error NothingToClaim();

    modifier onlyScratchCard() {
        if (msg.sender != scratchCard) revert Unauthorized();
        _;
    }

    constructor(address _usdc, address _owner) Ownable(_owner) {
        usdc = IERC20(_usdc);
    }

    function setScratchCard(address _scratchCard) external onlyOwner {
        scratchCard = _scratchCard;
    }

    // ─── Called by ScratchCard ────────────────────────────────────────────────

    /// @notice Links buyer to referrer on first purchase. Immutable after set.
    function registerReferral(address buyer, address referrer) external onlyScratchCard {
        if (referrer == buyer) revert SelfReferral();
        if (referrerOf[buyer] != address(0)) revert AlreadyReferred();
        referrerOf[buyer] = referrer;
        referralCount[referrer]++;
        emit ReferralRegistered(referrer, buyer);
    }

    /// @notice Credits `amount` USDC to the referrer of `buyer`.
    /// ScratchCard must have already transferred `amount` USDC to this contract.
    function creditReward(address buyer, uint256 amount) external onlyScratchCard {
        address referrer = referrerOf[buyer];
        if (referrer == address(0)) return;
        if (amount == 0) return;
        pendingRewards[referrer] += amount;
        totalEarned[referrer] += amount;
        emit ReferralEarned(referrer, buyer, amount);
    }

    // ─── Called by referrer ───────────────────────────────────────────────────

    /// @notice Referrer pulls all their accumulated USDC rewards.
    function claimRewards() external nonReentrant {
        uint256 amount = pendingRewards[msg.sender];
        if (amount == 0) revert NothingToClaim();
        pendingRewards[msg.sender] = 0;
        usdc.safeTransfer(msg.sender, amount);
        emit RewardsClaimed(msg.sender, amount);
    }

    // ─── Views ────────────────────────────────────────────────────────────────

    function isHustler(address referrer) external view returns (bool) {
        return referralCount[referrer] >= HUSTLER_THRESHOLD;
    }

    function getStats(address referrer) external view returns (
        uint256 count,
        uint256 pending,
        uint256 lifetime,
        bool hustler
    ) {
        count    = referralCount[referrer];
        pending  = pendingRewards[referrer];
        lifetime = totalEarned[referrer];
        hustler  = count >= HUSTLER_THRESHOLD;
    }
}
