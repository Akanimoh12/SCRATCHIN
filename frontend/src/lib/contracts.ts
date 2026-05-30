// Contract addresses — set these after deployment in .env.local
export const CONTRACT_ADDRESSES = {
  scratchCard: (process.env.NEXT_PUBLIC_SCRATCH_CARD_ADDRESS ?? "0x0000000000000000000000000000000000000000") as `0x${string}`,
  prizePool:   (process.env.NEXT_PUBLIC_PRIZE_POOL_ADDRESS   ?? "0x0000000000000000000000000000000000000000") as `0x${string}`,
  referral:    (process.env.NEXT_PUBLIC_REFERRAL_ADDRESS     ?? "0x0000000000000000000000000000000000000000") as `0x${string}`,
  // Unichain Sepolia USDC (6 decimals — set to your deployed USDC address)
  usdc:        (process.env.NEXT_PUBLIC_USDC_ADDRESS         ?? "0x0000000000000000000000000000000000000000") as `0x${string}`,
} as const;

// 0.5 USDC = 500_000 (6 decimals)
export const CARD_PRICE = BigInt("500000");

// USDC decimals
export const USDC_DECIMALS = 6;

// Format USDC bigint to human string e.g. "12.50"
export function formatUsdc(amount: bigint, decimals = 2): string {
  const n = Number(amount) / 1_000_000;
  return n.toFixed(decimals);
}
