// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// SCRATCHIN' Reactive Network RSC — built on the official reactive-lib (v0.2.0).
//
// Deployment: Reactive Lasna testnet (chain ID 5318007).
// Watches:    CardPurchased on ScratchCard (Unichain Sepolia, chain 1301).
// Action:     Emits Callback to trigger ScratchCard.revealCardCallback() on Unichain.
//
// WHY THE OLD VERSION DID NOT WORK:
//   1. It hand-rolled the system interface and called subscribe() from an external
//      owner tx. On Lasna the subscription registry is populated only when the
//      contract is recognized as a reactive contract — i.e. when subscribe() is
//      called from the RSC's own constructor against the injected service. The old
//      external call never registered a real subscription, so react() was never fired.
//   2. The callback payload targeted revealCard(uint256), but Reactive injects the
//      RVM id as the FIRST argument of every callback. The destination function must
//      be (address rvm_id, ...). The new target is revealCardCallback(address,uint256).
//   3. Authorization on the destination must accept the Reactive Callback Proxy as
//      msg.sender (set ScratchCard.reactiveRevealer = the proxy address, NOT this RSC).
//
// References (this repo): lib/reactive-lib/src/abstract-base/AbstractReactive.sol,
//                         lib/reactive-lib/src/interfaces/ISubscriptionService.sol

import {AbstractReactive} from "reactive-lib/abstract-base/AbstractReactive.sol";
import {IReactive} from "reactive-lib/interfaces/IReactive.sol";

contract ReactiveReveal is AbstractReactive {
    // ─── Constants ────────────────────────────────────────────────────────────

    // keccak256("CardPurchased(address,uint256,uint256)")
    uint256 private constant CARD_PURCHASED_TOPIC0 =
        uint256(keccak256("CardPurchased(address,uint256,uint256)"));

    uint256 private constant UNICHAIN_SEPOLIA_CHAIN_ID = 1301;

    // Gas to forward for the reveal callback on Unichain. 200k is safe for reveal logic.
    // A winning reveal does a USDC transfer + PrizePool payout + leaderboard writes,
    // which measured ~258k gas; a jackpot reveal is heavier still. 200k caused the
    // destination callback to run OUT OF GAS and revert (panic 0x11), leaving winning
    // cards stuck Pending. 500k gives ample headroom for the worst-case jackpot path.
    uint64 private constant CALLBACK_GAS_LIMIT = 500_000;

    // ─── State ────────────────────────────────────────────────────────────────

    address public owner;
    address public scratchCardAddress;

    // ─── Events ───────────────────────────────────────────────────────────────

    event RevealDispatched(uint256 indexed tokenId, address indexed buyer);

    // ─── Constructor ──────────────────────────────────────────────────────────

    /// @dev Subscription is created HERE, in the constructor, when this contract is
    ///      deployed to Reactive Lasna. `AbstractReactive` wires up `service` and
    ///      `vm` for us. On the real Reactive Network (vm == false) we register the
    ///      subscription; inside a ReactVM (vm == true) we skip it.
    ///
    ///      Constructor is `payable` so REACT can be sent WITH the deployment tx
    ///      (matches the official reactive-lib demos). The subscription must be
    ///      paid-for from birth or the ReactVM will not start delivering events —
    ///      funding the contract in a separate tx after deploy can leave the
    ///      subscription inactive.
    constructor(address _scratchCard) payable {
        owner = msg.sender;
        scratchCardAddress = _scratchCard;

        if (!vm) {
            service.subscribe(
                UNICHAIN_SEPOLIA_CHAIN_ID,
                _scratchCard,
                CARD_PURCHASED_TOPIC0,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE
            );
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /// @notice Owner can (re-)arm the subscription without redeploying — useful if a
    ///         subscription ever goes inactive. Reactive Network side only.
    function subscribe() external onlyOwner rnOnly {
        service.subscribe(
            UNICHAIN_SEPOLIA_CHAIN_ID,
            scratchCardAddress,
            CARD_PURCHASED_TOPIC0,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE
        );
    }

    // ─── IReactive: react() ─────────────────────────────────────────────────────

    /// @notice Invoked by the ReactVM when a subscribed CardPurchased event fires.
    /// @dev Must be gated with `vmOnly` (not `authorizedSenderOnly`): inside the
    ///      ReactVM the caller is the VM itself, not SERVICE_ADDR, so an ACL check
    ///      would revert and silently swallow every event (no Callback emitted).
    function react(LogRecord calldata log) external override vmOnly {
        // Defensive filtering — the subscription already scopes these.
        if (log.chain_id != UNICHAIN_SEPOLIA_CHAIN_ID) return;
        if (log._contract != scratchCardAddress) return;
        if (log.topic_0 != CARD_PURCHASED_TOPIC0) return;

        // CardPurchased(address indexed buyer, uint256 indexed tokenId, uint256 indexed purchaseBlock)
        address buyer = address(uint160(log.topic_1));
        uint256 tokenId = log.topic_2;

        // Reactive injects the RVM id into the FIRST arg slot; we pass address(0) as a
        // placeholder so the proxy can overwrite it. Destination must be
        // revealCardCallback(address rvm_id, uint256 tokenId).
        bytes memory payload = abi.encodeWithSignature(
            "revealCardCallback(address,uint256)",
            address(0),
            tokenId
        );

        emit Callback(UNICHAIN_SEPOLIA_CHAIN_ID, scratchCardAddress, CALLBACK_GAS_LIMIT, payload);
        emit RevealDispatched(tokenId, buyer);
    }

    // ─── Admin (Reactive Network side only) ─────────────────────────────────────

    /// @notice Re-point the watched ScratchCard. Re-subscribes the new address.
    function setScratchCard(address _addr) external onlyOwner rnOnly {
        service.unsubscribe(
            UNICHAIN_SEPOLIA_CHAIN_ID,
            scratchCardAddress,
            CARD_PURCHASED_TOPIC0,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE
        );
        scratchCardAddress = _addr;
        service.subscribe(
            UNICHAIN_SEPOLIA_CHAIN_ID,
            _addr,
            CARD_PURCHASED_TOPIC0,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE
        );
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}
