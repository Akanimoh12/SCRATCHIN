"use client";
import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { LuCopy, LuShare2, LuLoader, LuCircleCheck, LuGift } from "react-icons/lu";
import { TbBadgeFilled } from "react-icons/tb";
import { useAccount } from "wagmi";
import { useReferral } from "@/hooks/useReferral";
import { formatUsdc } from "@/lib/contracts";

export function ReferralPanel() {
  const { address } = useAccount();
  const {
    referralCount,
    pendingRewards,
    pendingUsdc,
    totalUsdc,
    isHustler,
    claimRewards,
    claiming,
    claimSuccess,
    refetch,
  } = useReferral(address);
  const [copied, setCopied] = useState(false);

  const referralUrl =
    address && typeof window !== "undefined"
      ? `${window.location.origin}?ref=${address}`
      : "";

  const handleCopy = () => {
    if (!referralUrl) return;
    navigator.clipboard.writeText(referralUrl);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleShare = () => {
    if (!referralUrl) return;
    if (navigator.share) {
      navigator.share({
        title: "SCRATCHIN'",
        text: "Play on-chain scratch cards — 5% of every card bought through your link goes to you!",
        url: referralUrl,
      });
    }
  };

  const toHustler = Math.max(0, 10 - Number(referralCount));
  const hustlerProgress = Math.min(100, (Number(referralCount) / 10) * 100);

  return (
    <div className="bg-white/3 border border-white/8 rounded-2xl p-6 space-y-5">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-linear-to-br from-[#FFD700] to-[#FF007A] flex items-center justify-center">
            <LuGift className="w-4.5 h-4.5 text-white" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h2 className="font-fire text-2xl tracking-widest text-white leading-tight">REFER & EARN</h2>
              {isHustler && (
                <span className="flex items-center gap-1 text-[#FFD700] text-xs font-bold bg-[#FFD700]/10 border border-[#FFD700]/30 px-2 py-0.5 rounded-full">
                  <TbBadgeFilled className="w-3 h-3" /> Hustler
                </span>
              )}
            </div>
            <p className="text-white/40 text-xs">5% of every card your referrals buy</p>
          </div>
        </div>
      </div>

      {/* Referral link */}
      <div className="bg-black/40 border border-white/8 rounded-xl px-3 py-2.5 flex items-center gap-2">
        <span className="text-white/40 font-mono text-xs truncate flex-1">
          {referralUrl || (address ? "Generating link..." : "Connect wallet to get your link")}
        </span>
        <button
          onClick={handleCopy}
          disabled={!referralUrl}
          className="text-white/40 hover:text-[#FC72FF] transition-colors shrink-0 disabled:opacity-30"
          title="Copy link"
        >
          {copied ? (
            <LuCircleCheck className="w-4 h-4 text-[#39FF14]" />
          ) : (
            <LuCopy className="w-4 h-4" />
          )}
        </button>
        <button
          onClick={handleShare}
          disabled={!referralUrl}
          className="text-white/40 hover:text-[#FC72FF] transition-colors shrink-0 disabled:opacity-30"
          title="Share link"
        >
          <LuShare2 className="w-4 h-4" />
        </button>
      </div>

      <AnimatePresence>
        {copied && (
          <motion.p
            initial={{ opacity: 0, y: -4 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0 }}
            className="text-[#39FF14] text-xs -mt-2"
          >
            Link copied!
          </motion.p>
        )}
      </AnimatePresence>

      {/* Stats row */}
      <div className="grid grid-cols-3 gap-3">
        <div className="bg-black/20 rounded-xl px-3 py-2.5 text-center">
          <div className="font-fire text-xs tracking-widest text-white/40">REFERRED</div>
          <div className="font-fire text-2xl tracking-widest text-white leading-tight">{referralCount.toString()}</div>
        </div>
        <div className="bg-black/20 rounded-xl px-3 py-2.5 text-center">
          <div className="font-fire text-xs tracking-widest text-white/40">CLAIMABLE</div>
          <div className="font-fire text-2xl tracking-widest text-[#FFD700] leading-tight">{pendingUsdc}</div>
        </div>
        <div className="bg-black/20 rounded-xl px-3 py-2.5 text-center">
          <div className="font-fire text-xs tracking-widest text-white/40">LIFETIME</div>
          <div className="font-fire text-2xl tracking-widest text-[#39FF14] leading-tight">{totalUsdc}</div>
        </div>
      </div>

      {/* Claim button */}
      {pendingRewards > BigInt(0) && (
        <motion.button
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.97 }}
          onClick={claimRewards}
          disabled={claiming}
          className="w-full py-3 rounded-xl font-black text-sm flex items-center justify-center gap-2 disabled:opacity-40"
          style={{
            background: "linear-gradient(135deg, #FFD700, #FF007A)",
            boxShadow: "0 0 20px #FFD70033",
          }}
        >
          {claiming ? (
            <><LuLoader className="w-4 h-4 animate-spin" /> Claiming...</>
          ) : (
            <>Claim {pendingUsdc} USDC</>
          )}
        </motion.button>
      )}

      <AnimatePresence>
        {claimSuccess && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: "auto" }}
            exit={{ opacity: 0, height: 0 }}
            className="flex items-center gap-2 text-[#39FF14] text-sm font-semibold"
          >
            <LuCircleCheck className="w-4 h-4" /> Rewards claimed!
          </motion.div>
        )}
      </AnimatePresence>

      {/* Hustler progress */}
      {!isHustler && (
        <div className="space-y-1.5">
          <div className="flex items-center justify-between text-xs">
            <span className="text-white/30">Hustler badge progress</span>
            <span className="text-white/50">{Number(referralCount)}/10 referrals</span>
          </div>
          <div className="h-1.5 bg-white/5 rounded-full overflow-hidden">
            <motion.div
              className="h-full rounded-full"
              style={{ background: "linear-gradient(90deg, #7B3FE4, #FFD700)" }}
              initial={{ width: 0 }}
              animate={{ width: `${hustlerProgress}%` }}
              transition={{ duration: 0.6, ease: "easeOut" }}
            />
          </div>
          {toHustler > 0 && (
            <p className="text-white/25 text-xs">
              {toHustler} more referral{toHustler !== 1 ? "s" : ""} to unlock the{" "}
              <span className="text-[#FFD700]">Hustler badge</span>
            </p>
          )}
        </div>
      )}
    </div>
  );
}
