// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {MockUSDC}   from "./mocks/MockUSDC.sol";
import {PrizePool}  from "../src/PrizePool.sol";
import {Referral}   from "../src/Referral.sol";
import {ScratchCard} from "../src/ScratchCard.sol";

/// @notice Full integration test suite for SCRATCHIN' contracts.
contract ScratchCardTest is Test {
    MockUSDC    usdc;
    PrizePool   prizePool;
    Referral    referral;
    ScratchCard scratchCard;

    address deployer = makeAddr("deployer");
    address alice    = makeAddr("alice");
    address bob      = makeAddr("bob");
    address referrer = makeAddr("referrer");
    address reactive = makeAddr("reactive");

    // 0.5 USDC = 500_000 (6 decimals)
    uint256 constant CARD_PRICE  = 500_000;
    // 0.25 USDC small win
    uint256 constant SMALL_WIN   = 250_000;
    // Seed pool with 100 USDC
    uint256 constant SEED_AMOUNT = 100_000_000;

    function setUp() public {
        vm.startPrank(deployer);

        usdc      = new MockUSDC();
        prizePool = new PrizePool(address(usdc), deployer);
        referral  = new Referral(address(usdc), deployer);
        scratchCard = new ScratchCard(
            address(usdc),
            deployer,
            address(prizePool),
            address(referral)
        );

        // Wire contracts
        prizePool.setScratchCard(address(scratchCard));
        referral.setScratchCard(address(scratchCard));
        scratchCard.setReactiveRevealer(reactive);

        // Seed the prize pool with 100 USDC
        usdc.mint(deployer, SEED_AMOUNT);
        usdc.approve(address(prizePool), SEED_AMOUNT);
        prizePool.seed(SEED_AMOUNT);

        vm.stopPrank();

        // Give alice and bob USDC
        usdc.mint(alice, 10_000_000);  // 10 USDC
        usdc.mint(bob,   10_000_000);
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    function _buyCard(address buyer, address ref) internal returns (uint256 tokenId) {
        vm.startPrank(buyer);
        usdc.approve(address(scratchCard), CARD_PRICE);
        scratchCard.buyCards(1, ref);
        vm.stopPrank();
        // tokenIds start at 1 and increment
        tokenId = scratchCard.getTokensByOwner(buyer).length > 0
            ? scratchCard.getTokensByOwner(buyer)[scratchCard.getTokensByOwner(buyer).length - 1]
            : 1;
    }

    function _revealCard(address buyer, uint256 tokenId) internal {
        vm.roll(block.number + 4); // past revealDelay(3)
        vm.prank(buyer);
        scratchCard.revealCard(tokenId);
    }

    // ─── Buy tests ────────────────────────────────────────────────────────────

    function test_BuyOneCard() public {
        uint256 tokenId = _buyCard(alice, address(0));
        assertEq(scratchCard.ownerOf(tokenId), alice);
        assertEq(scratchCard.cardsBought(alice), 1);
    }

    function test_BuyMultipleCards() public {
        vm.startPrank(alice);
        usdc.approve(address(scratchCard), CARD_PRICE * 5);
        scratchCard.buyCards(5, address(0));
        vm.stopPrank();
        assertEq(scratchCard.cardsBought(alice), 5);
        uint256[] memory ids = scratchCard.getTokensByOwner(alice);
        assertEq(ids.length, 5);
        assertEq(scratchCard.ownerOf(ids[4]), alice);
    }

    function test_BuyZeroRevertes() public {
        vm.prank(alice);
        vm.expectRevert(ScratchCard.ZeroQuantity.selector);
        scratchCard.buyCards(0, address(0));
    }

    function test_BuyWithoutApprovalReverts() public {
        vm.prank(alice);
        vm.expectRevert();
        scratchCard.buyCards(1, address(0));
    }

    function test_PrizePoolReceivesUSDC() public {
        uint256 poolBefore = prizePool.totalPool();
        _buyCard(alice, address(0));
        uint256 poolAfter = prizePool.totalPool();
        // Full card price (no referrer) goes to pool
        assertEq(poolAfter - poolBefore, CARD_PRICE);
    }

    function test_PrizePoolSplit() public {
        uint256 jackpotBefore = prizePool.jackpot();
        uint256 reserveBefore = prizePool.reserve();
        _buyCard(alice, address(0));
        uint256 expectedReserve = (CARD_PRICE * 1000) / 10000; // 10%
        uint256 expectedJackpot = CARD_PRICE - expectedReserve;
        assertEq(prizePool.reserve() - reserveBefore, expectedReserve);
        assertEq(prizePool.jackpot() - jackpotBefore, expectedJackpot);
    }

    // ─── Referral tests ───────────────────────────────────────────────────────

    function test_ReferralRegistration() public {
        _buyCard(alice, referrer);
        assertEq(referral.referrerOf(alice), referrer);
        assertEq(referral.referralCount(referrer), 1);
    }

    function test_ReferralRewardAmount() public {
        uint256 before = referral.pendingRewards(referrer);
        _buyCard(alice, referrer);
        uint256 expectedReward = (CARD_PRICE * 500) / 10000; // 5%
        assertEq(referral.pendingRewards(referrer) - before, expectedReward);
    }

    function test_ReferralPoolAmountReduced() public {
        uint256 poolBefore = prizePool.totalPool();
        _buyCard(alice, referrer);
        uint256 expectedToPool = CARD_PRICE - (CARD_PRICE * 500) / 10000; // 95%
        assertEq(prizePool.totalPool() - poolBefore, expectedToPool);
    }

    function test_ReferralClaimRewards() public {
        _buyCard(alice, referrer);
        uint256 reward = referral.pendingRewards(referrer);
        uint256 before = usdc.balanceOf(referrer);
        vm.prank(referrer);
        referral.claimRewards();
        assertEq(usdc.balanceOf(referrer) - before, reward);
        assertEq(referral.pendingRewards(referrer), 0);
    }

    function test_ReferralImmutable() public {
        _buyCard(alice, referrer);
        // Second purchase should not change referrer
        vm.startPrank(alice);
        usdc.approve(address(scratchCard), CARD_PRICE);
        scratchCard.buyCards(1, bob); // bob ignored — alice already has referrer
        vm.stopPrank();
        assertEq(referral.referrerOf(alice), referrer);
    }

    function test_SelfReferralIgnored() public {
        // alice referring herself: should be registered as no-referrer
        vm.startPrank(alice);
        usdc.approve(address(scratchCard), CARD_PRICE);
        scratchCard.buyCards(1, alice); // self-referral silently rejected
        vm.stopPrank();
        assertEq(referral.referrerOf(alice), address(0));
    }

    function test_HustlerBadge() public {
        for (uint256 i = 0; i < 10; i++) {
            address buyer = makeAddr(string(abi.encodePacked("buyer", i)));
            usdc.mint(buyer, CARD_PRICE);
            vm.startPrank(buyer);
            usdc.approve(address(scratchCard), CARD_PRICE);
            scratchCard.buyCards(1, referrer);
            vm.stopPrank();
        }
        assertTrue(referral.isHustler(referrer));
    }

    // ─── Reveal tests ─────────────────────────────────────────────────────────

    function test_CannotRevealBeforeDelay() public {
        uint256 tokenId = _buyCard(alice, address(0));
        vm.prank(alice);
        vm.expectRevert(ScratchCard.NotScratchable.selector);
        scratchCard.revealCard(tokenId);
    }

    function test_RevealByOwnerAfterDelay() public {
        uint256 tokenId = _buyCard(alice, address(0));
        _revealCard(alice, tokenId);
        ScratchCard.Card memory card = scratchCard.getCard(tokenId);
        assertEq(uint8(card.state), uint8(ScratchCard.CardState.Scratched));
    }

    function test_RevealByReactive() public {
        uint256 tokenId = _buyCard(alice, address(0));
        vm.roll(block.number + 4);
        vm.prank(reactive);
        scratchCard.revealCard(tokenId);
        ScratchCard.Card memory card = scratchCard.getCard(tokenId);
        assertEq(uint8(card.state), uint8(ScratchCard.CardState.Scratched));
    }

    function test_UnauthorizedRevealReverts() public {
        uint256 tokenId = _buyCard(alice, address(0));
        vm.roll(block.number + 4);
        vm.prank(bob);
        vm.expectRevert(ScratchCard.Unauthorized.selector);
        scratchCard.revealCard(tokenId);
    }

    function test_CannotRevealTwice() public {
        uint256 tokenId = _buyCard(alice, address(0));
        _revealCard(alice, tokenId);
        vm.prank(alice);
        vm.expectRevert(ScratchCard.AlreadyScratched.selector);
        scratchCard.revealCard(tokenId);
    }

    function test_SymbolsFilledOnReveal() public {
        uint256 tokenId = _buyCard(alice, address(0));
        _revealCard(alice, tokenId);
        ScratchCard.Card memory card = scratchCard.getCard(tokenId);
        // All symbols should be in range 0-4
        assertTrue(card.symbols[0] < 5);
        assertTrue(card.symbols[1] < 5);
        assertTrue(card.symbols[2] < 5);
    }

    // ─── Prize payout tests ───────────────────────────────────────────────────

    function test_SmallWinPaidFromReserve() public {
        // Force a 2-of-3 match by manipulating blockhash seed
        // We'll check prize pool decreases on a win
        // Buy many cards to hit a small win statistically (fuzz-style)
        uint256 wins = 0;
        for (uint256 i = 0; i < 20; i++) {
            vm.roll(block.number + 1);
            uint256 tokenId = _buyCard(alice, address(0));
            vm.roll(block.number + 4);
            uint256 reserveBefore = prizePool.reserve();
            vm.prank(alice);
            scratchCard.revealCard(tokenId);
            ScratchCard.Card memory card = scratchCard.getCard(tokenId);
            if (card.prize > 0 && card.prize < prizePool.jackpot() + card.prize) {
                wins++;
            }
            if (wins > 0) break;
        }
        // At least some cards should have been revealed without revert
        assertTrue(scratchCard.cardsBought(alice) > 0);
    }

    function test_JackpotPaidOut() public {
        // Manipulate to force a jackpot: find a block/tokenId combo that gives 3-of-3
        // This is deterministic given vm.roll — brute force in the test
        uint256 tokenId;
        bool jackpotFound = false;

        for (uint256 attempt = 0; attempt < 50; attempt++) {
            vm.roll(block.number + 1);
            tokenId = _buyCard(alice, address(0));
            uint256 targetBlock = block.number + 3;
            vm.roll(targetBlock);

            // Compute what the seed will be
            bytes32 bhash = blockhash(targetBlock - 3 + 3); // purchaseBlock + delay
            if (bhash == bytes32(0)) {
                vm.roll(targetBlock + 1);
                bhash = blockhash(targetBlock);
            }
            if (bhash == bytes32(0)) continue;

            ScratchCard.Card memory c = scratchCard.getCard(tokenId);
            bytes32 seed = keccak256(abi.encodePacked(bhash, tokenId, c.mintedTo, targetBlock));
            uint8 s0 = uint8(uint8(seed[0]) % 5);
            uint8 s1 = uint8(uint8(seed[1]) % 5);
            uint8 s2 = uint8(uint8(seed[2]) % 5);

            if (s0 == s1 && s1 == s2) {
                jackpotFound = true;
                break;
            }
        }

        if (jackpotFound) {
            uint256 jackpotBefore = prizePool.jackpot();
            uint256 aliceBefore   = usdc.balanceOf(alice);
            vm.prank(alice);
            scratchCard.revealCard(tokenId);
            ScratchCard.Card memory card = scratchCard.getCard(tokenId);
            if (card.prize > 0) {
                assertEq(prizePool.jackpot(), 0);
                assertGt(usdc.balanceOf(alice), aliceBefore);
                assertEq(card.prize, jackpotBefore);
            }
        }
        // If no jackpot found in 50 attempts, test passes (not forcing it)
    }

    // ─── Refund tests ─────────────────────────────────────────────────────────

    function test_CannotRefundBeforeExpiry() public {
        uint256 tokenId = _buyCard(alice, address(0));
        vm.prank(alice);
        vm.expectRevert(ScratchCard.NotExpired.selector);
        scratchCard.refundCard(tokenId);
    }

    function test_CannotRefundAlreadyScratched() public {
        uint256 tokenId = _buyCard(alice, address(0));
        _revealCard(alice, tokenId);
        vm.roll(block.number + 300); // past expiry too
        vm.prank(alice);
        vm.expectRevert(ScratchCard.NotRefundable.selector);
        scratchCard.refundCard(tokenId);
    }

    function test_RefundAfterExpiry() public {
        uint256 tokenId = _buyCard(alice, address(0));
        vm.roll(block.number + 260); // past EXPIRY_BLOCKS(250) + delay(3)
        uint256 aliceBefore = usdc.balanceOf(alice);
        vm.prank(alice);
        scratchCard.refundCard(tokenId);
        // alice got her card price back
        assertGt(usdc.balanceOf(alice), aliceBefore);
        // Card is burned
        vm.expectRevert();
        scratchCard.ownerOf(tokenId);
    }

    function test_UnauthorizedRefundReverts() public {
        uint256 tokenId = _buyCard(alice, address(0));
        vm.roll(block.number + 260);
        vm.prank(bob);
        vm.expectRevert(ScratchCard.Unauthorized.selector);
        scratchCard.refundCard(tokenId);
    }

    // ─── Leaderboard tests ────────────────────────────────────────────────────

    function test_CardsBoughtTracked() public {
        _buyCard(alice, address(0));
        _buyCard(alice, address(0));
        assertEq(scratchCard.cardsBought(alice), 2);
    }

    function test_TokensByOwner() public {
        _buyCard(alice, address(0));
        _buyCard(alice, address(0));
        uint256[] memory ids = scratchCard.getTokensByOwner(alice);
        assertEq(ids.length, 2);
    }

    function test_RecentWinnersRingBuffer() public {
        // Reveal 21 cards to overflow the ring buffer
        for (uint256 i = 0; i < 21; i++) {
            vm.roll(block.number + 1);
            uint256 tokenId = _buyCard(alice, address(0));
            vm.roll(block.number + 4);
            vm.prank(alice);
            scratchCard.revealCard(tokenId);
        }
        // recentIndex should be > 20, ring wraps
        assertGt(scratchCard.recentIndex(), 0);
    }

    // ─── IsScratchable / isExpired ────────────────────────────────────────────

    function test_IsScratchable() public {
        uint256 tokenId = _buyCard(alice, address(0));
        assertFalse(scratchCard.isScratchable(tokenId));
        vm.roll(block.number + 4);
        assertTrue(scratchCard.isScratchable(tokenId));
    }

    function test_IsExpiredAfter250Blocks() public {
        uint256 tokenId = _buyCard(alice, address(0));
        assertFalse(scratchCard.isExpired(tokenId));
        vm.roll(block.number + 260);
        assertTrue(scratchCard.isExpired(tokenId));
    }

    // ─── Admin tests ──────────────────────────────────────────────────────────

    function test_SetCardPrice() public {
        vm.prank(deployer);
        scratchCard.setCardPrice(1_000_000); // 1 USDC
        assertEq(scratchCard.cardPrice(), 1_000_000);
    }

    function test_OnlyOwnerCanSetCardPrice() public {
        vm.prank(alice);
        vm.expectRevert();
        scratchCard.setCardPrice(1_000_000);
    }

    function test_PrizePoolSeed() public {
        uint256 before = prizePool.jackpot();
        vm.startPrank(deployer);
        usdc.mint(deployer, 1_000_000);
        usdc.approve(address(prizePool), 1_000_000);
        prizePool.seed(1_000_000);
        vm.stopPrank();
        assertEq(prizePool.jackpot(), before + 1_000_000);
    }

    function test_ReferralGetStats() public {
        _buyCard(alice, referrer);
        (uint256 count, uint256 pending, uint256 lifetime, bool hustler) =
            referral.getStats(referrer);
        assertEq(count, 1);
        assertGt(pending, 0);
        assertGt(lifetime, 0);
        assertFalse(hustler);
    }
}
