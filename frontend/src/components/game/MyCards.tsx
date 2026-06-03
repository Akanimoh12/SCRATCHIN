"use client";
import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  LuHourglass, LuCircleCheck, LuCircleX,
  LuLoader, LuRefreshCw, LuChevronLeft, LuChevronRight,
} from "react-icons/lu";
import { TbDiamondsFilled, TbPlayCardStarFilled } from "react-icons/tb";
import { FaStar, FaBell, FaBolt, FaCircle } from "react-icons/fa6";
import {
  useWriteContract, useWaitForTransactionReceipt,
  useBlockNumber,
} from "wagmi";
import { SCRATCH_CARD_ABI } from "@/abis/ScratchCard";
import { CONTRACT_ADDRESSES, formatUsdc } from "@/lib/contracts";
import { usePlayerCards, type CardData } from "@/hooks/usePlayerCards";

const SYMBOLS = [
  { Icon: TbDiamondsFilled, label: "Gem",    color: "#FC72FF" },
  { Icon: FaStar,           label: "Star",   color: "#FFD700" },
  { Icon: FaBell,           label: "Bell",   color: "#FF007A" },
  { Icon: FaBolt,           label: "Bolt",   color: "#39FF14" },
  { Icon: FaCircle,         label: "Circle", color: "#7B3FE4" },
];

// Priority: jackpot → small win → ready → waiting → expired → refunded/loss
function cardPriority(c: CardData, block: bigint): number {
  const isJackpot  = c.state === 1 && c.symbols[0] === c.symbols[1] && c.symbols[1] === c.symbols[2] && c.prize > BigInt(0);
  const isWin      = c.state === 1 && c.prize > BigInt(0) && !isJackpot;
  const canReveal  = c.state === 0 && block >= c.purchaseBlock + BigInt(3) && block < c.purchaseBlock + BigInt(250);
  const isExpired  = c.state === 0 && block >= c.purchaseBlock + BigInt(250);
  if (isJackpot)  return 0;
  if (isWin)      return 1;
  if (canReveal)  return 2;
  if (c.state === 0 && !isExpired) return 3;
  if (isExpired)  return 4;
  return 5;
}

type Props = { tokenIds: bigint[] };

export function MyCards({ tokenIds }: Props) {
  const { cards, refetch } = usePlayerCards(tokenIds);
  const { data: blockNumber } = useBlockNumber({ watch: true });
  const [activeIdx, setActiveIdx] = useState(0);

  if (tokenIds.length === 0) return null;

  const block  = blockNumber ?? BigInt(0);
  const sorted = [...cards].sort((a, b) => cardPriority(a, block) - cardPriority(b, block));
  const safeIdx = Math.min(activeIdx, Math.max(0, sorted.length - 1));

  return (
    <div className="space-y-5">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="font-fire text-2xl tracking-widest text-white flex items-center gap-2">
          <TbPlayCardStarFilled className="w-5 h-5 text-[#FC72FF]" />
          YOUR CARDS
          <span className="text-white/30 font-sans font-normal text-sm tracking-normal">
            ({tokenIds.length})
          </span>
        </h2>
        <button
          onClick={() => refetch()}
          className="text-white/30 hover:text-white/70 transition-colors p-1"
          title="Refresh"
        >
          <LuRefreshCw className="w-4 h-4" />
        </button>
      </div>

      {/* Fan + nav row */}
      <div className="flex items-center gap-3">
        {/* Prev */}
        <button
          onClick={() => setActiveIdx(i => Math.max(0, i - 1))}
          disabled={safeIdx === 0}
          className="shrink-0 w-10 h-10 rounded-full flex items-center justify-center bg-white/5 border border-white/10 text-white/50 hover:text-white hover:border-white/30 transition-all disabled:opacity-20 disabled:cursor-not-allowed"
        >
          <LuChevronLeft className="w-5 h-5" />
        </button>

        {/* Fan container — full available width, fixed height */}
        <div className="flex-1 relative flex items-center justify-center" style={{ height: 220 }}>
          {sorted.map((card, i) => {
            const offset = i - safeIdx;
            if (Math.abs(offset) > 2) return null;

            const isActive = offset === 0;
            const rotate   = offset === 0 ? 0 : offset < 0 ? -11 : 11;
            // Shift side cards so they peek out from behind center
            const translateX = offset === 0 ? "0%" : offset < 0 ? "-48%" : "48%";
            const scale      = isActive ? 1 : 0.84;
            const opacity    = isActive ? 1 : Math.abs(offset) === 1 ? 0.65 : 0.35;
            const zIndex     = isActive ? 20 : Math.abs(offset) === 1 ? 10 : 5;

            return (
              <motion.div
                key={card.tokenId.toString()}
                className="absolute cursor-pointer"
                style={{ zIndex }}
                animate={{ rotate, x: translateX, scale, opacity }}
                transition={{ type: "spring", stiffness: 280, damping: 26 }}
                onClick={() => !isActive && setActiveIdx(i)}
              >
                <CardFace
                  card={card}
                  block={block}
                  isActive={isActive}
                  onDone={refetch}
                />
              </motion.div>
            );
          })}
        </div>

        {/* Next */}
        <button
          onClick={() => setActiveIdx(i => Math.min(sorted.length - 1, i + 1))}
          disabled={safeIdx === sorted.length - 1}
          className="shrink-0 w-10 h-10 rounded-full flex items-center justify-center bg-white/5 border border-white/10 text-white/50 hover:text-white hover:border-white/30 transition-all disabled:opacity-20 disabled:cursor-not-allowed"
        >
          <LuChevronRight className="w-5 h-5" />
        </button>
      </div>

      {/* Dots */}
      {sorted.length > 1 && (
        <div className="flex items-center justify-center gap-1.5 pb-1">
          {sorted.map((_, i) => (
            <button
              key={i}
              onClick={() => setActiveIdx(i)}
              className="rounded-full transition-all duration-200"
              style={{
                width:  i === safeIdx ? 22 : 7,
                height: 7,
                background: i === safeIdx ? "#FF007A" : "rgba(255,255,255,0.18)",
              }}
            />
          ))}
        </div>
      )}
    </div>
  );
}

// ── Card face ─────────────────────────────────────────────────────────────────

function CardFace({
  card, block, isActive, onDone,
}: {
  card: CardData; block: bigint; isActive: boolean; onDone: () => void;
}) {
  const isPending   = card.state === 0;
  const isScratched = card.state === 1;
  const isRefunded  = card.state === 2;

  const canReveal = isPending && block >= card.purchaseBlock + BigInt(3) && block < card.purchaseBlock + BigInt(250);
  const isExpired = isPending && block >= card.purchaseBlock + BigInt(250);
  const isJackpot  = isScratched && card.symbols[0] === card.symbols[1] && card.symbols[1] === card.symbols[2] && card.prize > BigInt(0);
  const isSmallWin = isScratched && !isJackpot && card.prize > BigInt(0);
  const isLoss     = isScratched && card.prize === BigInt(0);

  const { writeContract: reveal, data: revealHash, isPending: revealing } = useWriteContract();
  const { isLoading: revealConfirming } = useWaitForTransactionReceipt({ hash: revealHash, onReplaced: onDone });
  const { writeContract: refund, data: refundHash, isPending: refunding } = useWriteContract();
  const { isLoading: refundConfirming } = useWaitForTransactionReceipt({ hash: refundHash, onReplaced: onDone });
  const working = revealing || revealConfirming || refunding || refundConfirming;

  const doReveal = (e: React.MouseEvent) => {
    e.stopPropagation();
    reveal({ address: CONTRACT_ADDRESSES.scratchCard, abi: SCRATCH_CARD_ABI, functionName: "revealCard", args: [card.tokenId] });
  };
  const doRefund = (e: React.MouseEvent) => {
    e.stopPropagation();
    refund({ address: CONTRACT_ADDRESSES.scratchCard, abi: SCRATCH_CARD_ABI, functionName: "refundCard", args: [card.tokenId] });
  };

  // Background gradient per state
  const bg = isJackpot  ? "linear-gradient(135deg,#2e1e00,#4a3100,#2e1e00)"
           : isSmallWin ? "linear-gradient(135deg,#0a2010,#0d3318,#0a2010)"
           : canReveal  ? "linear-gradient(135deg,#1e0018,#30002a,#150020)"
           : isExpired  ? "linear-gradient(135deg,#1a1205,#221800,#1a1205)"
           :              "linear-gradient(135deg,#0c0c1a,#101020,#0c0c1a)";

  const border = isJackpot  ? "#FFD700"
               : isSmallWin ? "#39FF14"
               : canReveal  ? "#FF007A"
               : isExpired  ? "#f97316"
               : isRefunded ? "rgba(255,255,255,0.06)"
               :              "rgba(255,255,255,0.10)";

  const glow = isJackpot  ? "0 8px 40px #FFD70044, 0 24px 60px rgba(0,0,0,0.7)"
             : isSmallWin ? "0 8px 30px #39FF1433, 0 24px 60px rgba(0,0,0,0.7)"
             : canReveal  ? "0 8px 30px #FF007A44, 0 24px 60px rgba(0,0,0,0.7)"
             :              "0 16px 48px rgba(0,0,0,0.6)";

  return (
    <div
      className="relative rounded-3xl overflow-hidden select-none"
      style={{
        /* Responsive width: clamp between 240px and 300px so it fills small phones
           but doesn't blow out on desktop where the fan container has lots of room */
        width: "min(300px, 72vw)",
        height: "min(185px, 44.5vw)",
        background: bg,
        border: `1.5px solid ${border}`,
        boxShadow: glow,
        opacity: isRefunded ? 0.5 : 1,
      }}
    >
      {/* Horizontal texture lines */}
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          backgroundImage:
            "repeating-linear-gradient(0deg,transparent,transparent 15px,rgba(255,255,255,0.012) 15px,rgba(255,255,255,0.012) 16px)",
        }}
      />

      {/* Top row */}
      <div className="relative flex items-center justify-between px-5 pt-4">
        <span className="font-mono text-xs text-white/30">
          #{card.tokenId.toString().padStart(4, "0")}
        </span>
        <StatusBadge {...{ isJackpot, isSmallWin, isLoss, isRefunded, canReveal, isExpired, isPending }} />
      </div>

      {/* Symbols — vertically centred in the remaining space */}
      <div className="relative flex items-center justify-center" style={{ marginTop: "6px" }}>
        {isScratched ? (
          <motion.div
            initial={{ rotateY: 90, opacity: 0 }}
            animate={{ rotateY: 0, opacity: 1 }}
            transition={{ duration: 0.45 }}
            className="flex gap-2.5"
          >
            {card.symbols.map((s, i) => {
              const sym   = SYMBOLS[s] ?? SYMBOLS[0];
              const Icon  = sym.Icon;
              const match = (s === card.symbols[0] && s === card.symbols[1])
                          || (s === card.symbols[1] && s === card.symbols[2])
                          || (s === card.symbols[0] && s === card.symbols[2]);
              return (
                <div
                  key={i}
                  className="rounded-xl flex items-center justify-center"
                  style={{
                    width: 52, height: 52,
                    background: match ? `${sym.color}22` : "rgba(255,255,255,0.05)",
                    border: `1.5px solid ${match ? sym.color + "60" : "rgba(255,255,255,0.08)"}`,
                    boxShadow: match ? `0 0 14px ${sym.color}44` : "none",
                  }}
                >
                  <Icon style={{ width: 22, height: 22, color: match ? sym.color : "rgba(255,255,255,0.2)" }} />
                </div>
              );
            })}
          </motion.div>
        ) : (
          <div className="flex gap-2.5">
            {[0, 1, 2].map((i) => (
              <motion.div
                key={i}
                className="rounded-xl"
                style={{ width: 52, height: 52, border: "1.5px solid rgba(255,255,255,0.08)" }}
                animate={{ opacity: [0.2, 0.55, 0.2] }}
                transition={{ duration: 2, repeat: Infinity, delay: i * 0.4 }}
                css-note="shimmer placeholder"
              >
                <div
                  className="w-full h-full rounded-xl"
                  style={{ background: "linear-gradient(135deg,rgba(255,255,255,0.06),rgba(255,255,255,0.12),rgba(255,255,255,0.06))" }}
                />
              </motion.div>
            ))}
          </div>
        )}
      </div>

      {/* Bottom row: prize left / action button right */}
      <div className="relative flex items-center justify-between px-5 pb-4 mt-2">
        <div className="font-black text-sm leading-tight">
          {isJackpot  && <span className="text-[#FFD700]">🏆 {formatUsdc(card.prize, 2)} USDC</span>}
          {isSmallWin && <span className="text-[#39FF14]">+{formatUsdc(card.prize, 2)} USDC</span>}
          {isLoss     && <span className="text-white/25">No win</span>}
          {isRefunded && <span className="text-white/30">Refunded</span>}
          {isPending && !canReveal && !isExpired &&
            <span className="text-white/30 font-normal text-xs">~3 blocks to reveal</span>}
        </div>

        {isActive && canReveal && (
          <motion.button
            whileHover={{ scale: 1.06 }} whileTap={{ scale: 0.94 }}
            onClick={doReveal} disabled={working}
            className="px-4 py-1.5 rounded-xl font-fire text-base tracking-widest text-white disabled:opacity-40"
            style={{ background: "linear-gradient(135deg,#FF007A,#7B3FE4)", boxShadow: "0 0 16px #FF007A55" }}
          >
            {working ? <LuLoader className="w-4 h-4 animate-spin" /> : "SCRATCH!"}
          </motion.button>
        )}

        {isActive && isExpired && (
          <motion.button
            whileHover={{ scale: 1.06 }} whileTap={{ scale: 0.94 }}
            onClick={doRefund} disabled={working}
            className="px-4 py-1.5 rounded-xl font-fire text-base tracking-widest text-orange-400 border border-orange-500/40 disabled:opacity-40"
          >
            {working ? <LuLoader className="w-4 h-4 animate-spin" /> : "REFUND"}
          </motion.button>
        )}
      </div>
    </div>
  );
}

// ── Status badge ──────────────────────────────────────────────────────────────

function StatusBadge({ isJackpot, isSmallWin, isLoss, isRefunded, canReveal, isExpired, isPending }: {
  isJackpot: boolean; isSmallWin: boolean; isLoss: boolean;
  isRefunded: boolean; canReveal: boolean; isExpired: boolean; isPending: boolean;
}) {
  if (isJackpot)  return <span className="font-fire text-xs tracking-widest text-[#FFD700]">JACKPOT</span>;
  if (isSmallWin) return <span className="font-fire text-xs tracking-widest text-[#39FF14]">WIN</span>;
  if (isLoss)     return <span className="font-fire text-xs tracking-widest text-white/25">NO WIN</span>;
  if (isRefunded) return <span className="font-fire text-xs tracking-widest text-white/30">REFUNDED</span>;
  if (isExpired)  return <span className="font-fire text-xs tracking-widest text-orange-400">EXPIRED</span>;
  if (canReveal)  return (
    <motion.span
      animate={{ opacity: [1, 0.4, 1] }}
      transition={{ duration: 1.1, repeat: Infinity }}
      className="font-fire text-xs tracking-widest text-[#FF007A]"
    >
      READY
    </motion.span>
  );
  return (
    <span className="font-fire text-xs tracking-widest text-white/30 flex items-center gap-1">
      <LuHourglass className="w-3 h-3" /> WAIT
    </span>
  );
}
