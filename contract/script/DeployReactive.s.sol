// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {ReactiveReveal} from "../src/ReactiveReveal.sol";

/// @notice Deploy ReactiveReveal RSC on Reactive Lasna testnet (chain 5318007).
///
/// Prerequisites:
///   - PRIVATE_KEY in .env  (deployer holds REACT on Lasna)
///   - SCRATCH_CARD_ADDRESS in .env (the ScratchCard on Unichain Sepolia)
///
/// Run:
///   forge script script/DeployReactive.s.sol \
///     --rpc-url "https://lasna-rpc.rnk.dev" \
///     --broadcast -vvvv
///
/// IMPORTANT — what changed and why it now fires:
///   * Subscription is created inside the RSC constructor (reactive-lib model), so the
///     ReactVM actually starts watching CardPurchased. No manual subscribe() tx.
///   * We send REACT to the RSC so it can settle callback/subscription debt on Lasna.
///   * The callback targets revealCardCallback(address,uint256) on Unichain, executed by
///     the Reactive Callback Proxy. You MUST authorize that proxy on the destination:
///         cast send <SCRATCH_CARD> "setReactiveRevealer(address)" <CALLBACK_PROXY_ADDR>
///     (the proxy address, NOT this RSC's Lasna address).
contract DeployReactiveScript is Script {
    // REACT funding for the RSC to cover subscription + callback debt on Lasna.
    uint256 constant RSC_REACT_FUND = 0.5 ether;

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);
        address scratchCardAddr = vm.envAddress("SCRATCH_CARD_ADDRESS");

        console.log("Deployer    :", deployer);
        console.log("ScratchCard :", scratchCardAddr);

        vm.startBroadcast(deployerKey);

        // Deploy RSC — the constructor subscribes to CardPurchased on Unichain.
        ReactiveReveal rsc = new ReactiveReveal(scratchCardAddr);
        console.log("ReactiveReveal:", address(rsc));

        // Fund the RSC with REACT so it can cover callback/subscription debt.
        (bool ok,) = address(rsc).call{value: RSC_REACT_FUND}("");
        require(ok, "REACT funding failed");
        console.log("Funded RSC with 0.5 REACT");

        vm.stopBroadcast();

        console.log("=== Reactive Deployment Complete ===");
        console.log("Chain   : Reactive Lasna (5318007)");
        console.log("RSC addr:", address(rsc));
        console.log("Watching: CardPurchased on", scratchCardAddr);
        console.log("");
        console.log("NEXT STEPS (on Unichain Sepolia):");
        console.log("  Unichain Sepolia Callback Proxy: 0x9299472A6399Fd1027ebF067571Eb3e3D7837FC4");
        console.log("  1. Authorize the proxy as the revealer:");
        console.log("       cast send <SCRATCH_CARD> 'setReactiveRevealer(address)' \\");
        console.log("         0x9299472A6399Fd1027ebF067571Eb3e3D7837FC4");
        console.log("  2. Fund the proxy so it pays reveal gas on Unichain (depositTo, per docs).");
        console.log("  3. Update frontend: NEXT_PUBLIC_REACTIVE_RSC_ADDRESS=", address(rsc));
    }
}
