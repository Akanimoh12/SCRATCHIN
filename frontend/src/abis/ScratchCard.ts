export const SCRATCH_CARD_ABI = [
  // ─── Write ──────────────────────────────────────────────────────────────────
  {
    name: "buyCards",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "quantity", type: "uint256" },
      { name: "referrer", type: "address" },
    ],
    outputs: [],
  },
  {
    name: "revealCard",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [{ name: "tokenId", type: "uint256" }],
    outputs: [],
  },
  {
    name: "refundCard",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [{ name: "tokenId", type: "uint256" }],
    outputs: [],
  },
  // ─── Views ──────────────────────────────────────────────────────────────────
  {
    name: "getCard",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "tokenId", type: "uint256" }],
    outputs: [
      {
        name: "",
        type: "tuple",
        components: [
          { name: "mintedTo",      type: "address" },
          { name: "purchaseBlock", type: "uint256" },
          { name: "pricePaid",     type: "uint256" },
          { name: "state",         type: "uint8" },   // 0=Pending, 1=Scratched, 2=Refunded
          { name: "symbols",       type: "uint8[3]" },
          { name: "prize",         type: "uint256" },
        ],
      },
    ],
  },
  {
    name: "getTokensByOwner",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "addr", type: "address" }],
    outputs: [{ name: "", type: "uint256[]" }],
  },
  {
    name: "getRecentWinners",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [
      { name: "winners",    type: "address[20]" },
      { name: "prizes",     type: "uint256[20]" },
      { name: "timestamps", type: "uint256[20]" },
    ],
  },
  {
    name: "isScratchable",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "tokenId", type: "uint256" }],
    outputs: [{ name: "", type: "bool" }],
  },
  {
    name: "isExpired",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "tokenId", type: "uint256" }],
    outputs: [{ name: "", type: "bool" }],
  },
  {
    name: "cardPrice",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    name: "cardsBought",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "", type: "address" }],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    name: "totalWins",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "", type: "address" }],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    name: "totalWinnings",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "", type: "address" }],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    name: "winsThisWeek",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "", type: "address" }],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    name: "recentIndex",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }],
  },
  // ─── Events ─────────────────────────────────────────────────────────────────
  {
    name: "CardPurchased",
    type: "event",
    inputs: [
      { name: "buyer",         type: "address", indexed: true },
      { name: "tokenId",       type: "uint256", indexed: true },
      { name: "purchaseBlock", type: "uint256", indexed: true },
    ],
  },
  {
    name: "CardRevealed",
    type: "event",
    inputs: [
      { name: "tokenId", type: "uint256", indexed: true },
      { name: "winner",  type: "address", indexed: true },
      { name: "s0",      type: "uint8",   indexed: false },
      { name: "s1",      type: "uint8",   indexed: false },
      { name: "s2",      type: "uint8",   indexed: false },
      { name: "prize",   type: "uint256", indexed: false },
    ],
  },
  {
    name: "CardRefunded",
    type: "event",
    inputs: [
      { name: "tokenId", type: "uint256", indexed: true },
      { name: "owner",   type: "address", indexed: true },
      { name: "amount",  type: "uint256", indexed: false },
    ],
  },
] as const;
