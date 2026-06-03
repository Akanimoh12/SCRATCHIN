"use client";
import Link from "next/link";
import { useAccount } from "wagmi";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { motion } from "framer-motion";
import { LuTicket, LuWallet, LuArrowLeft } from "react-icons/lu";
import { useWatchContractEvent } from "wagmi";
import confetti from "canvas-confetti";
import { JackpotTicker } from "@/components/ui/JackpotTicker";
import { BuyCards } from "@/components/game/BuyCards";
import { MyCards } from "@/components/game/MyCards";
import { ReferralPanel } from "@/components/game/ReferralPanel";
import { Leaderboard } from "@/components/game/Leaderboard";
import { SCRATCH_CARD_ABI } from "@/abis/ScratchCard";
import { CONTRACT_ADDRESSES } from "@/lib/contracts";
import { useUsdcBalance } from "@/hooks/useUsdcBalance";
import { usePlayerTokenIds } from "@/hooks/usePlayerCards";

export function GameDashboard() {
  const { address } = useAccount();
  const { balanceFormatted } = useUsdcBalance(address);
  const { tokenIds, refetch: refetchIds } = usePlayerTokenIds(address);

  useWatchContractEvent({
    address: CONTRACT_ADDRESSES.scratchCard,
    abi: SCRATCH_CARD_ABI,
    eventName: "CardRevealed",
    onLogs(logs) {
      for (const log of logs) {
        const { s0, s1, s2, prize } = log.args as {
          s0: number; s1: number; s2: number; prize: bigint;
        };
        if (s0 === s1 && s1 === s2 && prize > BigInt(0)) {
          confetti({
            particleCount: 280, spread: 130, origin: { y: 0.55 },
            colors: ["#FF007A", "#FC72FF", "#7B3FE4", "#FFD700", "#ffffff"],
          });
        }
      }
    },
  });

  return (
    <div className="min-h-screen bg-[#08080F] text-white flex flex-col">

      {/* ── Nav ─────────────────────────────────────────────────────────── */}
      <nav className="flex items-center justify-between px-5 md:px-10 py-4 border-b border-white/5 bg-black/40 backdrop-blur sticky top-0 z-30">
        <div className="flex items-center gap-3 md:gap-4">
          <Link
            href="/"
            className="flex items-center gap-1.5 text-white/40 hover:text-white/80 transition-colors text-sm font-semibold"
          >
            <LuArrowLeft className="w-4 h-4" />
            <span className="hidden sm:inline">Home</span>
          </Link>
          <div className="w-px h-5 bg-white/10" />
          <div className="flex items-center gap-2">
            <div className="w-7 h-7 rounded-lg flex items-center justify-center bg-linear-to-br from-[#FF007A] to-[#7B3FE4]">
              <LuTicket className="w-3.5 h-3.5 text-white" />
            </div>
            <span className="font-fire text-xl tracking-wider">
              SCRATCH<span className="text-[#FC72FF]">IN&apos;</span>
            </span>
          </div>
        </div>

        <div className="flex items-center gap-2 md:gap-3">
          <div className="hidden sm:flex items-center gap-1.5 bg-white/5 border border-white/8 rounded-xl px-3 py-1.5 text-sm">
            <LuWallet className="w-3.5 h-3.5 text-[#FC72FF]" />
            <span className="font-semibold text-white">{balanceFormatted}</span>
            <span className="text-white/40 text-xs">USDC</span>
          </div>
          <ConnectButton />
        </div>
      </nav>

      {/* ── Page body ────────────────────────────────────────────────────── */}
      <div className="flex-1 w-full max-w-7xl mx-auto px-4 md:px-8 xl:px-10 py-6 md:py-10 space-y-6 md:space-y-8">

        {/* Jackpot — full width on desktop, hidden on mobile */}
        <div className="hidden md:block">
          <JackpotTicker />
        </div>

        {/* ── GAME AREA ──────────────────────────────────────────────────── */}
        {/*
            Mobile:  YOUR CARDS (full width, order 1) → BUY CARDS (full width, order 2)
            Desktop: YOUR CARDS left flex-1 (order 1) | BUY CARDS right w-[420px] (order 2)
        */}
        <div className="flex flex-col lg:flex-row gap-6 lg:gap-8 items-start">

          {/* LEFT / TOP: YOUR CARDS fan */}
          <div className="w-full lg:flex-1 order-1">
            {tokenIds.length > 0 ? (
              <MyCards tokenIds={tokenIds} />
            ) : (
              /* Empty state card placeholder — shows the fan shape even with no cards */
              <EmptyCardSlot />
            )}
          </div>

          {/* RIGHT / BOTTOM: BUY SCRATCH CARDS */}
          <div className="w-full lg:w-105 shrink-0 order-2">
            <BuyCards onPurchased={refetchIds} />
          </div>
        </div>

        {/* Referral + Leaderboard */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <ReferralPanel />
          <Leaderboard />
        </div>
      </div>

      {/* ── Footer ──────────────────────────────────────────────────────── */}
      <footer className="border-t border-white/5 py-5 px-6 flex flex-col sm:flex-row items-center justify-between gap-2 text-white/25 text-xs font-semibold">
        <span className="font-fire text-base tracking-wider text-[#FF007A]/60">SCRATCHIN&apos;</span>
        <span>Unichain Sepolia · Uniswap V4 · Reactive Network</span>
      </footer>
    </div>
  );
}

function EmptyCardSlot() {
  return (
    <div className="space-y-4">
      <div className="flex items-center gap-2">
        <span className="font-fire text-2xl tracking-widest text-white/25">YOUR CARDS</span>
      </div>
      {/* Ghost fan — compact height */}
      <div className="relative flex items-center justify-center" style={{ height: 190 }}>
        {/* Back-left card */}
        <div className="absolute rounded-3xl border border-white/10"
          style={{ width: 260, height: 160, background: "rgba(255,0,122,0.04)", transform: "rotate(-10deg) translateX(-40%) scale(0.82)", zIndex: 5 }} />
        {/* Back-right card */}
        <div className="absolute rounded-3xl border border-white/10"
          style={{ width: 260, height: 160, background: "rgba(123,63,228,0.04)", transform: "rotate(10deg) translateX(40%) scale(0.82)", zIndex: 5 }} />
        {/* Center card — slightly more visible */}
        <div className="absolute rounded-3xl border border-[#FF007A]/20 flex flex-col items-center justify-center gap-2"
          style={{ width: 260, height: 160, background: "linear-gradient(135deg,rgba(255,0,122,0.06),rgba(123,63,228,0.08))", zIndex: 20 }}>
          <div className="text-white/30 font-fire text-lg tracking-widest">NO CARDS YET</div>
          <div className="text-white/20 text-xs font-semibold">Buy your first scratch card →</div>
        </div>
      </div>
    </div>
  );
}
