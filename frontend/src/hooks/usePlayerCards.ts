"use client";
import { useReadContracts, useReadContract, useWatchContractEvent } from "wagmi";
import { SCRATCH_CARD_ABI } from "@/abis/ScratchCard";
import { CONTRACT_ADDRESSES } from "@/lib/contracts";

export type CardData = {
  tokenId:       bigint;
  mintedTo:      `0x${string}`;
  purchaseBlock: bigint;
  pricePaid:     bigint;
  state:         number;   // 0=Pending, 1=Scratched, 2=Refunded
  symbols:       readonly [number, number, number];
  prize:         bigint;
};

export function usePlayerTokenIds(address: `0x${string}` | undefined) {
  const { data, refetch } = useReadContract({
    address: CONTRACT_ADDRESSES.scratchCard,
    abi: SCRATCH_CARD_ABI,
    functionName: "getTokensByOwner",
    args: [address!],
    query: { enabled: !!address, refetchInterval: 3000 },
  });

  // Immediately re-fetch when this wallet buys a card
  useWatchContractEvent({
    address: CONTRACT_ADDRESSES.scratchCard,
    abi: SCRATCH_CARD_ABI,
    eventName: "CardPurchased",
    onLogs: () => refetch(),
  });

  return { tokenIds: (data as bigint[] | undefined) ?? [], refetch };
}

export function usePlayerCards(tokenIds: bigint[]) {
  const contracts = tokenIds.map((id) => ({
    address: CONTRACT_ADDRESSES.scratchCard,
    abi: SCRATCH_CARD_ABI,
    functionName: "getCard" as const,
    args: [id] as const,
  }));

  const { data, refetch } = useReadContracts({
    contracts,
    query: { enabled: tokenIds.length > 0, refetchInterval: 2000 },
  });

  const cards: CardData[] = (data ?? [])
    .map((result, i) => {
      if (result.status !== "success" || !result.result) return null;
      const d = result.result as {
        mintedTo:      `0x${string}`;
        purchaseBlock: bigint;
        pricePaid:     bigint;
        state:         number;
        symbols:       readonly [number, number, number];
        prize:         bigint;
      };
      return { tokenId: tokenIds[i], ...d };
    })
    .filter(Boolean) as CardData[];

  useWatchContractEvent({
    address: CONTRACT_ADDRESSES.scratchCard,
    abi: SCRATCH_CARD_ABI,
    eventName: "CardRevealed",
    onLogs: () => refetch(),
  });

  return { cards, refetch };
}
