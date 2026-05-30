# SCRATCHIN' — Frontend

Next.js 16 frontend for the SCRATCHIN' on-chain scratch card game. Connects to contracts on Unichain Sepolia via wagmi + RainbowKit.

**Routes:**
- `/` — Public landing page (no wallet required)
- `/play` — Game dashboard (wallet connect optional, but required to buy cards)

---

## Tech Stack

| Package | Version | Purpose |
|---|---|---|
| Next.js | 16 | App Router, SSR/client components |
| wagmi | 2.x | React hooks for contract reads/writes |
| viem | 2.x | Low-level EVM interaction |
| RainbowKit | 2.x | Wallet connect UI |
| @tanstack/react-query | 5.x | Async state + caching |
| Framer Motion | 12.x | Card reveal + page animations |
| Tailwind CSS | 4.x | Styling |
| react-icons | 5.x | Icons (lu, tb, fa6, si sets) |
| canvas-confetti | 1.x | Jackpot celebration |

---

## Prerequisites

- Node.js 18+ and npm
- Contracts deployed on Unichain Sepolia (see `../contract/README.md`)
- A free [WalletConnect project ID](https://cloud.walletconnect.com)
- MetaMask or any wallet with Unichain Sepolia added

**Add Unichain Sepolia to your wallet:**

| Field | Value |
|---|---|
| Network name | Unichain Sepolia |
| RPC URL | `https://sepolia.unichain.org` |
| Chain ID | `1301` |
| Currency | ETH |
| Explorer | https://unichain-sepolia.blockscout.com |

---

## Setup

```bash
cd frontend

# 1. Install dependencies
npm install

# 2. Copy env template
cp .env.example .env.local

# 3. Fill in .env.local (see below)
```

### Required `.env.local` values

```env
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=   # from cloud.walletconnect.com
NEXT_PUBLIC_USDC_ADDRESS=               # Unichain Sepolia USDC
NEXT_PUBLIC_SCRATCH_CARD_ADDRESS=       # from forge script deploy output
NEXT_PUBLIC_PRIZE_POOL_ADDRESS=         # from forge script deploy output
NEXT_PUBLIC_REFERRAL_ADDRESS=           # from forge script deploy output
```

---

## Run Locally

```bash
npm run dev
```

Open http://localhost:3000 — the landing page is public. Navigate to `/play` or click **Play Now** to interact with contracts.

---

## Project Structure

```
src/
├── app/
│   ├── layout.tsx          # Root layout — fonts, providers, metadata
│   ├── globals.css         # Tailwind + fire font utilities
│   ├── page.tsx            # Landing page (/)
│   └── play/
│       └── page.tsx        # Game dashboard (/play)
│
├── components/
│   ├── Providers.tsx       # wagmi + RainbowKit + React Query providers
│   ├── ui/
│   │   ├── JackpotTicker.tsx      # Live jackpot display
│   │   └── ParticleBackground.tsx # Canvas particle animation
│   └── game/
│       ├── GameDashboard.tsx      # Main game layout
│       ├── BuyCards.tsx           # USDC approve + buy flow
│       ├── MyCards.tsx            # Card grid with reveal/refund
│       ├── ReferralPanel.tsx      # Referral link + claim rewards
│       └── Leaderboard.tsx        # Recent winners + tabs
│
├── hooks/
│   ├── useUsdcBalance.ts    # USDC balance + allowance
│   ├── usePlayerCards.ts    # Token IDs + card data for connected wallet
│   ├── useJackpot.ts        # Live jackpot amount from PrizePool
│   ├── useReferral.ts       # Referral stats + claim
│   └── useRecentWinners.ts  # Ring buffer winners from ScratchCard
│
├── abis/
│   ├── ScratchCard.ts
│   ├── PrizePool.ts
│   ├── Referral.ts
│   └── ERC20.ts
│
└── lib/
    ├── contracts.ts         # Addresses + formatUsdc helper
    └── wagmi.ts             # wagmi config + Unichain Sepolia chain
```

---

## Game Flow (User Perspective)

1. Visit `/play` — landing page stays public, no forced redirect
2. Connect wallet via RainbowKit (top-right nav)
3. **Buy Cards**: approve USDC once (10x approval to reduce prompts), then buy 1–50 cards
4. Cards appear in **Your Cards** as pending (shimmer placeholders)
5. After 3 blocks (~6 seconds), **SCRATCH!** button appears — click to reveal
6. Reactive Network may auto-reveal before you click
7. Match 2 symbols → 0.25 USDC prize paid instantly to wallet
8. Match 3 symbols → full jackpot paid + confetti explosion
9. Cards not revealed within 250 blocks → **Refund** button appears

---

## Deploy to Vercel

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel

# Set environment variables in Vercel dashboard (Settings → Environment Variables)
# Add all NEXT_PUBLIC_* variables from .env.example
```

Or push to GitHub and import the repo at https://vercel.com/new — Vercel auto-detects Next.js.

> Set all `NEXT_PUBLIC_*` env vars in the Vercel project settings before deploying — the app needs them at build time.

---

## Notes

- Wallet connect is **optional on the landing page** — users browse freely
- The `/play` route always shows the game — wallet is only required to transact
- RainbowKit accent color is `#FF007A` (Unichain pink) — set in `Providers.tsx`
- `tokensByOwner` on the contract is append-only — cards you transfer away still show in your list (use the card state to filter)
