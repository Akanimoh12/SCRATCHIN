// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// SCRATCHIN' Reactive Network RSC — correct interface per reactive-lib v1.
//
// Deployment: Reactive Lasna testnet (chain ID 5318007).
// Watches:    CardPurchased on ScratchCard (Unichain Sepolia, chain 1301).
// Action:     Emits Callback to trigger ScratchCard.revealCard() after revealDelay blocks.

// ─── Reactive Network interfaces (from reactive-lib) ──────────────────────────

address constant REACTIVE_SYSTEM_CONTRACT = 0x0000000000000000000000000000000000fffFfF;

// REACTIVE_IGNORE: wildcard for topic filters — match any value
uint256 constant REACTIVE_IGNORE = 0xa65f96fc951c35ead38878e0f0b7a3c744a6f5ccc1476b313353ce31712313ad;

interface ISystemContract {
    function subscribe(
        uint256 chainId,
        address contractAddress,
        uint256 topic0,
        uint256 topic1,
        uint256 topic2,
        uint256 topic3
    ) external;

    function unsubscribe(
        uint256 chainId,
        address contractAddress,
        uint256 topic0,
        uint256 topic1,
        uint256 topic2,
        uint256 topic3
    ) external;
}

// IReactive: the actual interface Reactive VM calls and the Callback event it watches.
interface IReactive {
    struct LogRecord {
        uint256 chain_id;
        address _contract;
        uint256 topic_0;
        uint256 topic_1;
        uint256 topic_2;
        uint256 topic_3;
        bytes   data;
        uint256 block_number;
        uint256 op_code;
        uint256 block_hash;
        uint256 tx_hash;
        uint256 log_index;
    }

    // Reactive Network watches for this exact event to deliver cross-chain callbacks.
    // gas_limit: how much gas to forward on the destination chain call.
    event Callback(
        uint256 indexed chain_id,
        address indexed _contract,
        uint64  indexed gas_limit,
        bytes   payload
    );
}

// ─── ReactiveReveal ───────────────────────────────────────────────────────────

contract ReactiveReveal is IReactive {
    // ─── Constants ────────────────────────────────────────────────────────────

    // keccak256("CardPurchased(address,uint256,uint256)")
    uint256 public constant CARD_PURCHASED_TOPIC0 =
        uint256(keccak256("CardPurchased(address,uint256,uint256)"));

    uint256 public constant UNICHAIN_SEPOLIA_CHAIN_ID = 1301;

    // Gas to forward for revealCard() on Unichain. 200k is safe for the reveal logic.
    uint64  public constant CALLBACK_GAS_LIMIT = 200_000;

    // ─── State ────────────────────────────────────────────────────────────────

    address public owner;
    address public scratchCardAddress;
    uint256 public revealDelay = 3;

    mapping(uint256 => uint256) public pendingRevealBlock;
    mapping(uint256 => address) public pendingBuyer;

    bool private _subscribed;

    // Detect whether we are running inside the Reactive VM (RVM) or on the real chain.
    // The RVM has no code at the system contract address; the real chain does.
    bool private immutable _isVM;

    // ─── Events ───────────────────────────────────────────────────────────────

    event RevealQueued(uint256 indexed tokenId, uint256 targetBlock);
    event RevealDispatched(uint256 indexed tokenId);

    // ─── Modifiers ────────────────────────────────────────────────────────────

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // Only the Reactive VM (system contract) can call react() in production.
    // Owner can call it directly for testing / manual fallback.
    modifier onlyVMOrOwner() {
        require(
            msg.sender == REACTIVE_SYSTEM_CONTRACT || msg.sender == owner,
            "Only VM or owner"
        );
        _;
    }

    // ─── Constructor ──────────────────────────────────────────────────────────

    constructor(address _scratchCard) {
        owner              = msg.sender;
        scratchCardAddress = _scratchCard;

        // Detect VM environment
        uint256 size;
        assembly { size := extcodesize(REACTIVE_SYSTEM_CONTRACT) }
        _isVM = (size == 0);
    }

    // ─── IReactive: react() ───────────────────────────────────────────────────

    /// @notice Called by the Reactive VM when a subscribed event fires on Unichain.
    function react(LogRecord calldata log) external onlyVMOrOwner {
        // Filter: only handle our specific event from our specific contract on Unichain
        if (log.chain_id != UNICHAIN_SEPOLIA_CHAIN_ID) return;
        if (log._contract != scratchCardAddress)       return;
        if (log.topic_0   != CARD_PURCHASED_TOPIC0)    return;

        // CardPurchased(address indexed buyer, uint256 indexed tokenId, uint256 indexed purchaseBlock)
        uint256 tokenId       = log.topic_2;
        uint256 purchaseBlock = log.topic_3;
        address buyer         = address(uint160(log.topic_1));

        uint256 targetBlock = purchaseBlock + revealDelay;
        pendingRevealBlock[tokenId] = targetBlock;
        pendingBuyer[tokenId]       = buyer;

        emit RevealQueued(tokenId, targetBlock);

        // Emit Callback — Reactive Network delivers this to ScratchCard on Unichain
        // after targetBlock is reached.
        bytes memory payload = abi.encodeWithSignature("revealCard(uint256)", tokenId);
        emit Callback(UNICHAIN_SEPOLIA_CHAIN_ID, scratchCardAddress, CALLBACK_GAS_LIMIT, payload);
        emit RevealDispatched(tokenId);
    }

    // ─── Subscription management ──────────────────────────────────────────────

    function subscribe() external onlyOwner {
        require(!_subscribed, "Already subscribed");
        _subscribed = true;
        ISystemContract(REACTIVE_SYSTEM_CONTRACT).subscribe(
            UNICHAIN_SEPOLIA_CHAIN_ID,
            scratchCardAddress,
            CARD_PURCHASED_TOPIC0,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE
        );
    }

    function unsubscribe() external onlyOwner {
        _subscribed = false;
        ISystemContract(REACTIVE_SYSTEM_CONTRACT).unsubscribe(
            UNICHAIN_SEPOLIA_CHAIN_ID,
            scratchCardAddress,
            CARD_PURCHASED_TOPIC0,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE
        );
    }

    // ─── Manual fallback ──────────────────────────────────────────────────────

    /// @notice Owner manually fires a reveal callback if Reactive is delayed.
    function manualDispatch(uint256 tokenId) external onlyOwner {
        require(pendingRevealBlock[tokenId] > 0, "No pending reveal");
        delete pendingRevealBlock[tokenId];
        delete pendingBuyer[tokenId];
        bytes memory payload = abi.encodeWithSignature("revealCard(uint256)", tokenId);
        emit Callback(UNICHAIN_SEPOLIA_CHAIN_ID, scratchCardAddress, CALLBACK_GAS_LIMIT, payload);
        emit RevealDispatched(tokenId);
    }

    // ─── Admin ────────────────────────────────────────────────────────────────

    function setScratchCard(address _addr) external onlyOwner {
        scratchCardAddress = _addr;
    }

    function setRevealDelay(uint256 _delay) external onlyOwner {
        revealDelay = _delay;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    receive() external payable {}
}
