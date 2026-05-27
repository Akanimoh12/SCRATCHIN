<div align="center">

# SCRATCHIN'

**On-Chain Scratch Card Game — Powered by Uniswap V4 · Reactive Network · Unichain**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Unichain](https://img.shields.io/badge/Chain-Unichain%20Sepolia-7B3FE4)](https://sepolia.uniscan.xyz)
[![Reactive Network](https://img.shields.io/badge/Automation-Reactive%20Lasna-00C2FF)](https://reactive.network)
[![Solidity](https://img.shields.io/badge/Solidity-^0.8.26-363636)](https://soliditylang.org)

*Scratch. Win. Repeat. On-chain forever.*

</div>

---

## What is SCRATCHIN'?

SCRATCHIN' is a fully on-chain scratch card lottery game deployed on **Unichain**. Players buy scratch card NFTs with ETH, wait for a target block, and reveal results using **block hash entropy**. The jackpot grows automatically from **Uniswap V4 swap fees** via a custom hook, and reveals are triggered autonomously by a **Reactive Network RSC** — no backend required.

---

## How It Works

```
Player → buyCards() → ScratchCard (ERC-721)
                            ↓
                       PrizePool (jackpot + reserve)
                            ↑
                     ScratchHook (V4 afterSwap fees)

Reactive Lasna RSC watches CardPurchased on Unichain →
  waits revealDelay blocks →
  calls revealCard() back on Unichain →
  block hash entropy determines 3 symbols →
  match 2 = small win from reserve
  match 3 = full jackpot
```

1. **Buy** — Pay 0.01 ETH per card. Cards are ERC-721 NFTs. Pass a referrer address for 5% cashback.
2. **Wait** — After 3 blocks, the card becomes scratchable. Reactive RSC auto-triggers reveal.
3. **Reveal** — Block hash of `(purchaseBlock + delay)` seeds 3 random symbols.
4. **Win** — 2-of-3 match pays from reserve. 3-of-3 wins the full jackpot.
5. **Leaderboard** — All wins logged on-chain. Weekly resets with Hall of Fame.
6. **Referral** — 5% of every referred purchase goes to the referrer. 10 referrals = Hustler badge.

---

## Deployed Contracts

### Unichain Sepolia (Chain ID: 1301)

| Contract | Address | Explorer |
|---|---|---|
| ScratchCard (ERC-721) | `TBD` | [View](https://unichain-sepolia.blockscout.com) |
| PrizePool | `TBD` | [View](https://unichain-sepolia.blockscout.com) |
| ScratchHook (V4) | `TBD` | [View](https://unichain-sepolia.blockscout.com) |
| Referral | `TBD` | [View](https://unichain-sepolia.blockscout.com) |

### Reactive Lasna Testnet (Chain ID: 5318007)

| Contract | Address | Explorer |
|---|---|---|
| ReactiveReveal RSC | `TBD` | [View](https://lasna.reactscan.net) |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Blockchain | Unichain Sepolia (L2) |
| Smart Contracts | Solidity ^0.8.26 · Foundry · ERC-721 |
| Swap Hook | Uniswap V4 `afterSwap` (fee diversion to prize pool) |
| Automation | Reactive Network RSC (block watcher → auto-reveal) |
| Randomness | Block hash entropy `(purchaseBlock + N)` |
| Frontend | Next.js 15 (App Router) · TypeScript · Tailwind CSS |
| Wallet | wagmi v2 · viem · RainbowKit |
| Animations | Framer Motion · canvas-confetti |
| Icons | Lucide React · React Icons |

---

## Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/) · [Node.js 20+](https://nodejs.org/)

### Install & Run

```bash
# Contracts
cd contract
cp .env.example .env       # fill in PRIVATE_KEY + RPC URLs
forge install
forge build
forge test

# Deploy to Unichain Sepolia
forge script script/Deploy.s.sol --rpc-url unichain_sepolia --broadcast --verify

# Deploy Reactive RSC (after setting SCRATCH_CARD_ADDRESS in .env)
forge script script/DeployReactive.s.sol --rpc-url reactive_lasna --broadcast

# Frontend
cd ../frontend
cp .env.example .env.local  # fill in contract addresses + WalletConnect project ID
npm install
npm run dev
# Open http://localhost:3000
```

### Testing

```bash
cd contract && forge test -v
```

---

## Project Structure

```
scratchin/
├── contract/
│   ├── src/
│   │   ├── ScratchCard.sol      # ERC-721 — buy, reveal, leaderboard
│   │   ├── PrizePool.sol        # Jackpot + reserve fund
│   │   ├── ScratchHook.sol      # Uniswap V4 afterSwap hook
│   │   ├── Referral.sol         # On-chain referral tracking
│   │   └── ReactiveReveal.sol   # Reactive Network RSC
│   ├── script/
│   │   ├── Deploy.s.sol         # Deploy to Unichain Sepolia
│   │   └── DeployReactive.s.sol # Deploy RSC to Reactive Lasna
│   ├── test/
│   │   └── ScratchCard.t.sol
│   └── foundry.toml
└── frontend/
    ├── src/
    │   ├── app/                 # Next.js App Router pages
    │   ├── components/
    │   │   ├── game/            # BuyCards, ScratchCardTile, GamePage, Leaderboard, ReferralPanel
    │   │   └── ui/              # JackpotTicker
    │   ├── hooks/               # useJackpot, usePlayerCards, useReferral
    │   ├── abis/                # ScratchCard, PrizePool, Referral ABIs
    │   └── lib/                 # wagmi config, contract addresses
    └── .env.example
```

---

## Smart Contract Logic

### Randomness
Block hash of `purchaseBlock + revealDelay` is used as the entropy seed. Since block hashes are only available for the last 256 blocks, the Reactive RSC triggers reveal promptly. Manual fallback reveal is also available.

### Prize Structure
- **3-of-3 match** → wins 100% of the jackpot
- **2-of-3 match** → wins `smallWinAmount` (0.005 ETH) from reserve
- **No match** → no payout

### Fee Diversion
The V4 `ScratchHook` accumulates 10% of swap fees on-chain. Anyone can call `flushFeesToPool()` to forward accumulated fees to the jackpot.

### Referral
One referrer per buyer, set immutably at first purchase. 5% of purchase value credited to referrer immediately. Claimable any time via `claimRewards()`.

---

## MVP Phase 1 Checklist

### Contracts
- [x] `ScratchCard.sol` — ERC-721, buy, reveal, leaderboard
- [x] `PrizePool.sol` — jackpot + reserve, payout logic
- [x] `ScratchHook.sol` — V4 hook, fee diversion
- [x] `Referral.sol` — on-chain referral, 5% reward, Hustler badge
- [x] `ReactiveReveal.sol` — Reactive RSC for auto-reveal
- [ ] Deploy to Unichain Sepolia testnet
- [ ] Deploy RSC to Reactive Lasna testnet

### Frontend
- [x] Landing page — jackpot ticker, how it works, recent winners
- [x] Game page — buy cards, scratch cards, referral panel, leaderboard
- [x] Wallet connect gate (landing → game transition)
- [x] Card scratch animation (Framer Motion reveal)
- [x] Confetti on jackpot win (canvas-confetti)
- [x] Referral link generation + copy/share
- [ ] Deploy to Vercel

---

## License

[MIT](LICENSE)

---

<div align="center">
Built with Uniswap V4 Hooks · Reactive Network · Unichain
</div>
