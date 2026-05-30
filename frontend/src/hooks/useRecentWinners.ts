"use client";
import { useReadContract } from "wagmi";
import { SCRATCH_CARD_ABI } from "@/abis/ScratchCard";
import { CONTRACT_ADDRESSES, formatUsdc } from "@/lib/contracts";

export type RecentWinner = {
  address: string;
  prize:   string;
  ago:     string;
};

function timeAgo(ts: bigint): string {
  const seconds = Math.floor(Date.now() / 1000) - Number(ts);
  if (seconds < 60)  return `${seconds}s ago`;
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
  return `${Math.floor(seconds / 86400)}d ago`;
}

function truncate(addr: string): string {
  if (!addr || addr === "0x0000000000000000000000000000000000000000") return "";
  return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
}

export function useRecentWinners() {
  const { data, refetch } = useReadContract({
    address: CONTRACT_ADDRESSES.scratchCard,
    abi: SCRATCH_CARD_ABI,
    functionName: "getRecentWinners",
    query: { refetchInterval: 6000 },
  });

  const winners: RecentWinner[] = [];
  if (data) {
    const [addrs, prizes, timestamps] = data as unknown as [
      readonly string[],
      readonly bigint[],
      readonly bigint[],
    ];
    for (let i = 0; i < 20; i++) {
      const addr = addrs[i];
      const prize = prizes[i];
      const ts    = timestamps[i];
      if (!addr || addr === "0x0000000000000000000000000000000000000000") continue;
      if (!prize || prize === BigInt(0)) continue;
      winners.push({
        address: truncate(addr),
        prize:   `${formatUsdc(prize, 2)} USDC`,
        ago:     timeAgo(ts),
      });
    }
  }

  return { winners, refetch };
}
