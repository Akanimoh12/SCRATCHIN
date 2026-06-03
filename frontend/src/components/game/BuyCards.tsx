"use client";
import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  useWriteContract, useWaitForTransactionReceipt,
  useAccount, useReadContract,
} from "wagmi";
import { LuTicket, LuArrowRight, LuCircleCheck, LuLoader } from "react-icons/lu";
import { SCRATCH_CARD_ABI } from "@/abis/ScratchCard";
import { ERC20_ABI } from "@/abis/ERC20";
import { CONTRACT_ADDRESSES, CARD_PRICE, formatUsdc } from "@/lib/contracts";
import { useUsdcBalance } from "@/hooks/useUsdcBalance";

type Props = { onPurchased?: () => void };

const PRESETS = [1, 5, 10];

export function BuyCards({ onPurchased }: Props) {
  const { address } = useAccount();
  const [quantity, setQuantity] = useState(1);
  const { allowance, refetch: refetchBalance } = useUsdcBalance(address);

  const referrer = (() => {
    if (typeof window === "undefined") return "0x0000000000000000000000000000000000000000" as `0x${string}`;
    const ref = new URLSearchParams(window.location.search).get("ref");
    return (ref?.startsWith("0x") ? ref : "0x0000000000000000000000000000000000000000") as `0x${string}`;
  })();

  const totalCost = CARD_PRICE * BigInt(quantity);
  const needsApproval = allowance < totalCost;

  // Approve
  const {
    writeContract: approve,
    data: approveHash,
    isPending: approving,
  } = useWriteContract();
  const { isLoading: approveConfirming, isSuccess: approveSuccess } =
    useWaitForTransactionReceipt({ hash: approveHash });

  // Buy
  const {
    writeContract: buy,
    data: buyHash,
    isPending: buying,
  } = useWriteContract();
  const { isLoading: buyConfirming, isSuccess: buySuccess } =
    useWaitForTransactionReceipt({
      hash: buyHash,
      onReplaced: () => { refetchBalance(); onPurchased?.(); },
    });

  // After approve confirmed, re-check allowance
  if (approveSuccess) refetchBalance();
  if (buySuccess) { refetchBalance(); onPurchased?.(); }

  const handleApprove = () => {
    approve({
      address: CONTRACT_ADDRESSES.usdc,
      abi: ERC20_ABI,
      functionName: "approve",
      args: [CONTRACT_ADDRESSES.scratchCard, totalCost * BigInt(10)], // approve 10x to avoid repeated prompts
    });
  };

  const handleBuy = () => {
    buy({
      address: CONTRACT_ADDRESSES.scratchCard,
      abi: SCRATCH_CARD_ABI,
      functionName: "buyCards",
      args: [BigInt(quantity), referrer],
    });
  };

  const isWorking = approving || approveConfirming || buying || buyConfirming;

  return (
    <div className="bg-white/3 border border-white/8 rounded-2xl p-6 space-y-5">
      {/* Header */}
      <div className="flex items-center gap-3">
        <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-[#FF007A] to-[#7B3FE4] flex items-center justify-center">
          <LuTicket className="w-4.5 h-4.5 text-white" />
        </div>
        <div>
          <h2 className="font-fire text-2xl tracking-widest text-white leading-tight">BUY SCRATCH CARDS</h2>
          <p className="text-white/40 text-xs">0.50 USDC each · Revealed in ~3 blocks</p>
        </div>
      </div>

      {/* Quantity picker */}
      <div className="space-y-3">
        <div className="flex gap-2 flex-wrap">
          {PRESETS.map((n) => (
            <button
              key={n}
              onClick={() => setQuantity(n)}
              className={`px-5 py-2.5 rounded-xl font-black text-base transition-all border ${
                quantity === n
                  ? "bg-[#FF007A] border-[#FF007A] text-white shadow-[0_0_20px_#FF007A55]"
                  : "bg-white/5 border-white/10 text-white/70 hover:border-white/20 hover:text-white"
              }`}
            >
              {n}
            </button>
          ))}
          <input
            type="number"
            min={1}
            max={50}
            value={quantity}
            onChange={(e) => setQuantity(Math.max(1, Math.min(50, parseInt(e.target.value) || 1)))}
            className="w-20 bg-white/5 border border-white/10 text-white text-center rounded-xl px-3 py-2 font-bold focus:border-[#FC72FF] outline-none text-sm"
          />
        </div>

        <div className="flex items-center justify-between text-sm">
          <span className="text-white/40">Total cost</span>
          <span className="font-black text-white text-lg">
            {formatUsdc(totalCost, 2)}{" "}
            <span className="text-[#FC72FF]">USDC</span>
          </span>
        </div>
      </div>

      {/* Action button */}
      {needsApproval ? (
        <motion.button
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.97 }}
          onClick={handleApprove}
          disabled={isWorking || !address}
          className="w-full py-4 rounded-xl font-black text-lg flex items-center justify-center gap-2 transition-all disabled:opacity-40"
          style={{
            background: "linear-gradient(135deg, #7B3FE4, #FC72FF)",
            boxShadow: "0 0 30px #7B3FE455",
          }}
        >
          {approving || approveConfirming ? (
            <><LuLoader className="w-5 h-5 animate-spin" /> Approving USDC...</>
          ) : (
            <>Approve USDC <LuArrowRight className="w-5 h-5" /></>
          )}
        </motion.button>
      ) : (
        <motion.button
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.97 }}
          onClick={handleBuy}
          disabled={isWorking || !address}
          className="w-full py-4 rounded-xl font-black text-lg flex items-center justify-center gap-2 transition-all disabled:opacity-40"
          style={{
            background: "linear-gradient(135deg, #FF007A, #7B3FE4)",
            boxShadow: "0 0 30px #FF007A44",
          }}
        >
          {buying || buyConfirming ? (
            <><LuLoader className="w-5 h-5 animate-spin" /> Minting {quantity} card{quantity > 1 ? "s" : ""}...</>
          ) : (
            <>
              <LuTicket className="w-5 h-5" />
              Scratch {quantity} Card{quantity > 1 ? "s" : ""}
            </>
          )}
        </motion.button>
      )}

      {/* Success message */}
      <AnimatePresence>
        {buySuccess && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: "auto" }}
            exit={{ opacity: 0, height: 0 }}
            className="flex items-center gap-2 text-[#39FF14] text-sm font-semibold"
          >
            <LuCircleCheck className="w-4 h-4" />
            {quantity} card{quantity > 1 ? "s" : ""} minted! Scroll down to scratch.
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
