"use client";
import { useState } from "react";
import { motion } from "framer-motion";
import { LuFlame, LuTrendingUp, LuCrown, LuTrophy, LuRefreshCw } from "react-icons/lu";
import { useRecentWinners } from "@/hooks/useRecentWinners";

type Tab = "recent" | "big" | "alltime";

const TABS: { key: Tab; label: string; Icon: React.ComponentType<{ className?: string }> }[] = [
  { key: "recent",  label: "Recent Wins", Icon: LuFlame },
  { key: "big",     label: "Biggest Win", Icon: LuTrendingUp },
  { key: "alltime", label: "All-Time",    Icon: LuCrown },
];

export function Leaderboard() {
  const [tab, setTab] = useState<Tab>("recent");
  const { winners, refetch } = useRecentWinners();

  // For "big" and "alltime" tabs we sort the same ring-buffer data differently
  const entries = (() => {
    if (tab === "recent") return winners.slice(0, 5);
    if (tab === "big") {
      return [...winners]
        .sort((a, b) => parseFloat(b.prize) - parseFloat(a.prize))
        .slice(0, 5);
    }
    // alltime: deduplicate by address, pick highest prize per address
    const map = new Map<string, typeof winners[0]>();
    for (const w of winners) {
      const existing = map.get(w.address);
      if (!existing || parseFloat(w.prize) > parseFloat(existing.prize)) {
        map.set(w.address, w);
      }
    }
    return [...map.values()]
      .sort((a, b) => parseFloat(b.prize) - parseFloat(a.prize))
      .slice(0, 5);
  })();

  const rankColor = (i: number) =>
    i === 0 ? "#FFD700" : i === 1 ? "#C0C0C0" : i === 2 ? "#CD7F32" : "rgba(255,255,255,0.2)";

  return (
    <div className="bg-white/3 border border-white/8 rounded-2xl p-6 space-y-5">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-linear-to-br from-[#FFD700] to-[#FF007A] flex items-center justify-center">
            <LuTrophy className="w-4.5 h-4.5 text-white" />
          </div>
          <h2 className="font-fire text-2xl tracking-widest text-fire-sm text-white leading-tight">LEADERBOARD</h2>
        </div>
        <button
          onClick={() => refetch()}
          className="text-white/30 hover:text-white/70 transition-colors"
          title="Refresh"
        >
          <LuRefreshCw className="w-4 h-4" />
        </button>
      </div>

      {/* Tabs */}
      <div className="flex gap-2">
        {TABS.map(({ key, label, Icon }) => (
          <button
            key={key}
            onClick={() => setTab(key)}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold transition-all border ${
              tab === key
                ? "bg-[#FF007A]/10 border-[#FF007A]/40 text-[#FF007A]"
                : "bg-white/5 border-white/8 text-white/50 hover:text-white/80 hover:border-white/15"
            }`}
          >
            <Icon className="w-3 h-3" /> {label}
          </button>
        ))}
      </div>

      {/* Entries */}
      <ol className="space-y-2">
        {entries.length === 0 ? (
          <li className="text-center text-white/25 text-sm py-6">
            No winners yet — be the first!
          </li>
        ) : (
          entries.map((entry, i) => (
            <motion.li
              key={`${entry.address}-${i}`}
              initial={{ opacity: 0, x: -8 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: i * 0.05 }}
              className="flex items-center gap-3 bg-black/20 rounded-xl px-4 py-2.5"
            >
              <span
                className="font-black text-sm w-5 text-center shrink-0"
                style={{ color: rankColor(i) }}
              >
                {i + 1}
              </span>
              <span className="text-white font-mono text-xs flex-1 truncate">{entry.address}</span>
              <span className="text-[#FFD700] font-black text-xs shrink-0">{entry.prize}</span>
              {tab === "recent" && (
                <span className="text-white/25 text-xs shrink-0">{entry.ago}</span>
              )}
            </motion.li>
          ))
        )}
      </ol>
    </div>
  );
}
