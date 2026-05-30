// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {ReactiveReveal} from "../src/ReactiveReveal.sol";

/// @notice Deploy ReactiveReveal RSC on Reactive Lasna testnet (chain 5318007).
///
/// Prerequisites:
///   - PRIVATE_KEY in .env
///   - REACTIVE_LASNA_RPC=https://lasna-rpc.rnk.dev in .env
///   - SCRATCH_CARD_ADDRESS in .env (set after Deploy.s.sol)
///
/// Run:
///   forge script script/DeployReactive.s.sol \
///     --rpc-url "https://lasna-rpc.rnk.dev" \
///     --broadcast \
///     -vvvv
contract DeployReactiveScript is Script {
    // How much ETH to send to the RSC for Reactive callback gas.
    // 0.5 ETH is enough for many thousands of auto-reveals on Lasna.
    uint256 constant RSC_ETH_FUND = 0.5 ether;

    function run() external {
        uint256 deployerKey     = vm.envUint("PRIVATE_KEY");
        address deployer        = vm.addr(deployerKey);
        address scratchCardAddr = vm.envAddress("SCRATCH_CARD_ADDRESS");

        console.log("Deployer       :", deployer);
        console.log("ScratchCard    :", scratchCardAddr);
        console.log("Funding RSC with:", RSC_ETH_FUND, "wei");

        vm.startBroadcast(deployerKey);

        // 1. Deploy RSC
        ReactiveReveal rsc = new ReactiveReveal(scratchCardAddr);
        console.log("ReactiveReveal :", address(rsc));

        // 2. Fund RSC with ETH so Reactive Network can pay for callback gas
        (bool ok,) = address(rsc).call{value: RSC_ETH_FUND}("");
        require(ok, "ETH funding failed");
        console.log("Funded RSC with 0.5 ETH for Reactive gas");

        // 3. Subscribe to CardPurchased events from ScratchCard on Unichain
        rsc.subscribe();
        console.log("Subscribed to CardPurchased events");

        vm.stopBroadcast();

        console.log("=== Reactive Deployment Complete ===");
        console.log("Chain          : Reactive Lasna (5318007)");
        console.log("RSC addr       :", address(rsc));
        console.log("Watching       : CardPurchased on", scratchCardAddr);
        console.log("");
        console.log("Next steps:");
        console.log("  1. Set SCRATCH_CARD_ADDRESS (Unichain) to allow RSC as revealer:");
        console.log("     cast send <SCRATCH_CARD> setReactiveRevealer(address) <RSC_ADDR>");
        console.log("  2. Update frontend: NEXT_PUBLIC_REACTIVE_RSC_ADDRESS=", address(rsc));
    }
}
