"use client";
import { useReadContracts } from "wagmi";
import { ERC20_ABI } from "@/abis/ERC20";
import { CONTRACT_ADDRESSES, formatUsdc } from "@/lib/contracts";

export function useUsdcBalance(address: `0x${string}` | undefined) {
  const { data, refetch } = useReadContracts({
    contracts: [
      {
        address: CONTRACT_ADDRESSES.usdc,
        abi: ERC20_ABI,
        functionName: "balanceOf",
        args: [address!],
      },
      {
        address: CONTRACT_ADDRESSES.usdc,
        abi: ERC20_ABI,
        functionName: "allowance",
        args: [address!, CONTRACT_ADDRESSES.scratchCard],
      },
    ],
    query: { enabled: !!address, refetchInterval: 8000 },
  });

  const balance   = (data?.[0]?.result as bigint | undefined) ?? BigInt(0);
  const allowance = (data?.[1]?.result as bigint | undefined) ?? BigInt(0);

  return {
    balance,
    allowance,
    balanceFormatted: formatUsdc(balance, 2),
    refetch,
  };
}
