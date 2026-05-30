"use client";
import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { REFERRAL_ABI } from "@/abis/Referral";
import { CONTRACT_ADDRESSES, formatUsdc } from "@/lib/contracts";

export function useReferral(address: `0x${string}` | undefined) {
  const { data, refetch } = useReadContract({
    address: CONTRACT_ADDRESSES.referral,
    abi: REFERRAL_ABI,
    functionName: "getStats",
    args: [address!],
    query: { enabled: !!address, refetchInterval: 8000 },
  });

  const { writeContract, data: claimHash, isPending: claiming } = useWriteContract();
  const { isLoading: claimConfirming, isSuccess: claimSuccess } =
    useWaitForTransactionReceipt({ hash: claimHash });

  const stats = data as
    | { count: bigint; pending: bigint; lifetime: bigint; hustler: boolean }
    | undefined;

  const referralCount  = stats?.count    ?? BigInt(0);
  const pendingRewards = stats?.pending  ?? BigInt(0);
  const totalEarned    = stats?.lifetime ?? BigInt(0);
  const isHustler      = stats?.hustler  ?? false;

  const claimRewards = () =>
    writeContract({
      address: CONTRACT_ADDRESSES.referral,
      abi: REFERRAL_ABI,
      functionName: "claimRewards",
    });

  return {
    referralCount,
    pendingRewards,
    pendingUsdc:  formatUsdc(pendingRewards, 2),
    totalUsdc:    formatUsdc(totalEarned, 2),
    isHustler,
    claimRewards,
    claiming: claiming || claimConfirming,
    claimSuccess,
    refetch,
  };
}
