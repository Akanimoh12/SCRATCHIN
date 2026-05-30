"use client";
import { useReadContract } from "wagmi";
import { PRIZE_POOL_ABI } from "@/abis/PrizePool";
import { CONTRACT_ADDRESSES, formatUsdc } from "@/lib/contracts";

export function useJackpot() {
  const { data, refetch } = useReadContract({
    address: CONTRACT_ADDRESSES.prizePool,
    abi: PRIZE_POOL_ABI,
    functionName: "jackpot",
    query: { refetchInterval: 5000 },
  });

  const jackpotRaw = data ?? BigInt(0);

  return {
    jackpotRaw,
    jackpotUsdc: formatUsdc(jackpotRaw, 2),   // e.g. "1200.00"
    refetch,
  };
}
