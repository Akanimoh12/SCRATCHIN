// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {PrizePool}  from "../src/PrizePool.sol";
import {Referral}   from "../src/Referral.sol";
import {ScratchCard} from "../src/ScratchCard.sol";
import {IERC20}     from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @notice Deploy SCRATCHIN' on Unichain Sepolia.
///
/// Prerequisites:
///   - Set PRIVATE_KEY in .env
///   - Set UNICHAIN_SEPOLIA_RPC in .env
///   - Set USDC_ADDRESS in .env (Unichain Sepolia USDC: check https://unichain-sepolia.blockscout.com)
///   - Deployer wallet must hold USDC for seeding (optional, set SEED_AMOUNT=0 to skip)
///
/// Run:
///   forge script script/Deploy.s.sol \
///     --rpc-url unichain_sepolia \
///     --broadcast \
///     --verify \
///     -vvvv
contract DeployScript is Script {
    // Unichain Sepolia USDC address (6 decimals)
    // Check current address at: https://unichain-sepolia.blockscout.com/tokens
    // Verify this address on https://unichain-sepolia.blockscout.com before deploying
    address constant UNICHAIN_SEPOLIA_USDC = address(0); // TODO: set before deploy

    function run() external {
        uint256 deployerKey  = vm.envUint("PRIVATE_KEY");
        address deployer     = vm.addr(deployerKey);
        address usdcAddr     = vm.envOr("USDC_ADDRESS", UNICHAIN_SEPOLIA_USDC);
        uint256 seedAmount   = vm.envOr("SEED_AMOUNT", uint256(50_000_000)); // default 50 USDC

        console.log("Deployer  :", deployer);
        console.log("USDC      :", usdcAddr);
        console.log("Seed amt  :", seedAmount);

        vm.startBroadcast(deployerKey);

        // 1. PrizePool
        PrizePool prizePool = new PrizePool(usdcAddr, deployer);
        console.log("PrizePool  :", address(prizePool));

        // 2. Referral
        Referral referral = new Referral(usdcAddr, deployer);
        console.log("Referral   :", address(referral));

        // 3. ScratchCard
        ScratchCard scratchCard = new ScratchCard(
            usdcAddr,
            deployer,
            address(prizePool),
            address(referral)
        );
        console.log("ScratchCard:", address(scratchCard));

        // 4. Wire up
        prizePool.setScratchCard(address(scratchCard));
        referral.setScratchCard(address(scratchCard));

        // 5. Seed prize pool (optional — requires deployer to hold USDC)
        if (seedAmount > 0) {
            IERC20(usdcAddr).approve(address(prizePool), seedAmount);
            prizePool.seed(seedAmount);
            console.log("Pool seeded with", seedAmount, "USDC (6 dec)");
        }

        vm.stopBroadcast();

        console.log("=== Deployment Complete ===");
        console.log("Chain      : Unichain Sepolia (1301)");
        console.log("USDC       :", usdcAddr);
        console.log("PrizePool  :", address(prizePool));
        console.log("Referral   :", address(referral));
        console.log("ScratchCard:", address(scratchCard));
        console.log("");
        console.log("Next steps:");
        console.log("  1. Set SCRATCH_CARD_ADDRESS=", address(scratchCard), "in .env");
        console.log("  2. Deploy ReactiveReveal on Lasna (chain 5318007) -- it subscribes in its constructor:");
        console.log("     forge script script/DeployReactive.s.sol --rpc-url reactive_lasna --broadcast");
        console.log("  3. Authorize the Callback Proxy as revealer (auto-reveal):");
        console.log("     cast send <SCRATCH_CARD> 'setReactiveRevealer(address)' 0x9299472A6399Fd1027ebF067571Eb3e3D7837FC4");
        console.log("  4. Update frontend .env.local with contract addresses");
    }
}
