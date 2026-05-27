// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// SCRATCHIN' Reactive Network RSC.
//
// Deployment: Reactive Lasna testnet (chain ID 5318007).
// Purpose:
//   1. Subscribes to CardPurchased events on Unichain Sepolia (chain 1301).
//   2. When react() is called by Reactive for a CardPurchased event,
//      it emits a Callback event to trigger ScratchCard.revealCard() after revealDelay blocks.
//
// Reactive Network pattern:
//   - The system contract handles subscriptions and cross-chain callbacks.
//   - react() is called by Reactive VM when a subscribed event fires.
//   - Emitting Callback(chainId, contract, payload) triggers a cross-chain call.
//
// Event: CardPurchased(address indexed buyer, uint256 indexed tokenId, uint256 indexed purchaseBlock)
//   topic0 = keccak256("CardPurchased(address,uint256,uint256)")

// Reactive Network system contract address (same on all Reactive chains)
address constant REACTIVE_SYSTEM_CONTRACT = 0x0000000000000000000000000000000000fffFfF;

// Unichain Sepolia chain ID
uint256 constant UNICHAIN_SEPOLIA_CHAIN_ID = 1301;

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

contract ReactiveReveal {
    // ─── Constants ────────────────────────────────────────────────────────────

    /// @dev keccak256("CardPurchased(address,uint256,uint256)")
    uint256 public constant CARD_PURCHASED_TOPIC0 =
        uint256(keccak256("CardPurchased(address,uint256,uint256)"));

    /// Wildcard — match any value for indexed params
    uint256 public constant REACTIVE_IGNORE = 0;

    // ─── State ────────────────────────────────────────────────────────────────

    address public owner;
    address public scratchCardAddress;
    uint256 public revealDelay = 3; // must match ScratchCard.revealDelay

    // tokenId => target reveal block on Unichain
    mapping(uint256 => uint256) public pendingRevealBlock;
    // tokenId => buyer (for callback auth)
    mapping(uint256 => address) public pendingBuyer;

    bool private _subscribed;

    // ─── Events ───────────────────────────────────────────────────────────────

    /// @notice Emitting this event tells Reactive Network to make a cross-chain callback.
    /// @param chainId     Destination chain (Unichain Sepolia = 1301)
    /// @param contractAddress  Target contract on the destination chain
    /// @param payload     ABI-encoded calldata to forward
    event Callback(uint256 indexed chainId, address indexed contractAddress, bytes payload);

    event RevealQueued(uint256 indexed tokenId, uint256 targetBlock);
    event RevealDispatched(uint256 indexed tokenId);

    // ─── Modifiers ────────────────────────────────────────────────────────────

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /// @dev In production Reactive calls react() via the system contract.
    ///      In tests / manual mode it can be called directly by the owner.
    modifier onlyReactiveOrOwner() {
        require(
            msg.sender == REACTIVE_SYSTEM_CONTRACT || msg.sender == owner,
            "Only Reactive or owner"
        );
        _;
    }

    // ─── Constructor ──────────────────────────────────────────────────────────

    constructor(address _scratchCard) {
        owner              = msg.sender;
        scratchCardAddress = _scratchCard;
    }

    // ─── Reactive callback ────────────────────────────────────────────────────

    /// @notice Called by Reactive Network when a subscribed event fires on Unichain.
    /// @param chainId        Source chain (1301 = Unichain Sepolia)
    /// @param _contract      Source contract address (our ScratchCard)
    /// @param topic0         Event signature hash
    /// @param topic1         Indexed param 1: buyer address (padded to uint256)
    /// @param topic2         Indexed param 2: tokenId
    /// @param topic3         Indexed param 3: purchaseBlock
    /// @param data           Non-indexed event data (empty for CardPurchased)
    function react(
        uint256 chainId,
        address _contract,
        uint256 topic0,
        uint256 topic1,
        uint256 topic2,
        uint256 topic3,
        bytes   calldata data
    ) external onlyReactiveOrOwner {
        // Validate this is the event we care about
        if (chainId != UNICHAIN_SEPOLIA_CHAIN_ID) return;
        if (_contract != scratchCardAddress) return;
        if (topic0 != CARD_PURCHASED_TOPIC0) return;

        uint256 tokenId       = topic2;
        uint256 purchaseBlock = topic3;
        address buyer         = address(uint160(topic1));

        uint256 targetBlock = purchaseBlock + revealDelay;
        pendingRevealBlock[tokenId] = targetBlock;
        pendingBuyer[tokenId]       = buyer;

        emit RevealQueued(tokenId, targetBlock);

        // Immediately emit a Callback. Reactive Network will hold it until
        // the target block is reached on Unichain, then forward it.
        bytes memory payload = abi.encodeWithSignature("revealCard(uint256)", tokenId);
        emit Callback(UNICHAIN_SEPOLIA_CHAIN_ID, scratchCardAddress, payload);
        emit RevealDispatched(tokenId);
    }

    // ─── Subscription management ──────────────────────────────────────────────

    /// @notice Subscribe to CardPurchased events from ScratchCard on Unichain.
    /// Call this once after deploying.
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

    /// @notice Owner can manually dispatch a reveal callback if Reactive fails.
    function manualDispatch(uint256 tokenId) external onlyOwner {
        require(pendingRevealBlock[tokenId] > 0, "No pending reveal");
        delete pendingRevealBlock[tokenId];
        delete pendingBuyer[tokenId];
        bytes memory payload = abi.encodeWithSignature("revealCard(uint256)", tokenId);
        emit Callback(UNICHAIN_SEPOLIA_CHAIN_ID, scratchCardAddress, payload);
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

    // Accept ETH for Reactive gas fees
    receive() external payable {}
}
