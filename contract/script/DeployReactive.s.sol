// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {ReactiveReveal} from "../src/ReactiveReveal.sol";

/// @notice Deploy ReactiveReveal RSC on Reactive Lasna testnet (chain 5318007).
///
/// Prerequisites:
///   - PRIVATE_KEY in .env
///   - REACTIVE_LASNA_RPC in .env (https://kopli-rpc.rkt.ink)
///   - SCRATCH_CARD_ADDRESS in .env (set after Deploy.s.sol)
///
/// Run:
///   forge script script/DeployReactive.s.sol \
///     --rpc-url reactive_lasna \
///     --broadcast \
///     -vvvv
///
/// After deploy: fund the RSC contract with a small amount of ETH for Reactive gas,
/// then call ReactiveReveal.subscribe() to begin watching CardPurchased events.
contract DeployReactiveScript is Script {
    function run() external {
        uint256 deployerKey      = vm.envUint("PRIVATE_KEY");
        address scratchCardAddr  = vm.envAddress("SCRATCH_CARD_ADDRESS");

        console.log("Deploying ReactiveReveal RSC...");
        console.log("ScratchCard on Unichain:", scratchCardAddr);

        vm.startBroadcast(deployerKey);

        ReactiveReveal rsc = new ReactiveReveal(scratchCardAddr);
        console.log("ReactiveReveal RSC:", address(rsc));

        vm.stopBroadcast();

        console.log("=== Reactive Deployment Complete ===");
        console.log("Chain     : Reactive Lasna (5318007)");
        console.log("RSC addr  :", address(rsc));
        console.log("");
        console.log("Next steps:");
        console.log("  1. Fund the RSC with ETH for Reactive gas fees");
        console.log("  2. Call ReactiveReveal.subscribe() on Lasna to start watching events");
        console.log("  3. Update frontend .env.local: NEXT_PUBLIC_REACTIVE_RSC=", address(rsc));
    }
}
