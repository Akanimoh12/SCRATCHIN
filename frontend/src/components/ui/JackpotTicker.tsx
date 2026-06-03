"use client";
import { motion, AnimatePresence } from "framer-motion";
import { LuTrophy } from "react-icons/lu";
import { useJackpot } from "@/hooks/useJackpot";

export function JackpotTicker() {
  const { jackpotUsdc } = useJackpot();

  return (
    <motion.div
      className="w-full flex items-center gap-5 rounded-2xl px-7 py-5 border border-[#FF007A]/25"
      style={{ background: "linear-gradient(135deg, rgba(255,0,122,0.08), rgba(123,63,228,0.12), rgba(0,0,0,0.6))" }}
      animate={{
        boxShadow: [
          "0 0 25px rgba(255,0,122,0.15)",
          "0 0 45px rgba(252,114,255,0.28)",
          "0 0 25px rgba(255,0,122,0.15)",
        ],
      }}
      transition={{ duration: 2.5, repeat: Infinity }}
    >
      <div
        className="w-14 h-14 rounded-2xl flex items-center justify-center shrink-0"
        style={{ background: "linear-gradient(135deg, #FF007A, #7B3FE4)", boxShadow: "0 0 20px #FF007A55" }}
      >
        <LuTrophy className="text-white w-7 h-7" />
      </div>

      <div className="flex-1 min-w-0">
        <div className="font-fire text-sm text-[#FC72FF]/70 tracking-[0.25em]">CURRENT JACKPOT</div>
        <AnimatePresence mode="wait">
          <motion.div
            key={jackpotUsdc}
            initial={{ y: -10, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            exit={{ y: 10, opacity: 0 }}
            className="font-fire text-4xl md:text-5xl tracking-widest text-white tabular-nums leading-none"
          >
            {jackpotUsdc}{" "}
            <span
              className="text-3xl md:text-4xl"
              style={{ background: "linear-gradient(90deg, #FF007A, #FC72FF)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent", backgroundClip: "text" }}
            >
              USDC
            </span>
          </motion.div>
        </AnimatePresence>
      </div>

      {/* Live dot */}
      <div className="flex items-center gap-1.5 shrink-0">
        <motion.span
          className="w-2 h-2 rounded-full bg-[#39FF14]"
          animate={{ opacity: [1, 0.3, 1], scale: [1, 0.8, 1] }}
          transition={{ duration: 1.5, repeat: Infinity }}
        />
        <span className="text-[#39FF14]/70 text-xs font-bold tracking-widest hidden sm:block">LIVE</span>
      </div>
    </motion.div>
  );
}
