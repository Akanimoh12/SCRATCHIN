"use client";
import Link from "next/link";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { motion } from "framer-motion";
import {
  LuZap, LuGem, LuFlame, LuShieldCheck,
  LuArrowRight, LuTicket, LuCrown, LuWallet, LuLayers,
} from "react-icons/lu";
import { SiEthereum } from "react-icons/si";
import { FaTrophy, FaMedal } from "react-icons/fa6";
import { ParticleBackground } from "@/components/ui/ParticleBackground";
import { JackpotTicker } from "@/components/ui/JackpotTicker";
import { useRecentWinners } from "@/hooks/useRecentWinners";

const PINK  = "#FF007A";
const PURP  = "#7B3FE4";
const LILAC = "#FC72FF";

const HOW_STEPS = [
  {
    icon: LuWallet,
    label: "01",
    title: "Connect & Approve",
    desc: "Connect your wallet on Unichain Sepolia. Approve USDC once — takes 10 seconds.",
    color: LILAC,
  },
  {
    icon: LuTicket,
    label: "02",
    title: "Buy Scratch Cards",
    desc: "Each card costs 0.50 USDC. Buy 1 to 50 at a time. Your card is minted as an NFT on-chain.",
    color: PINK,
  },
  {
    icon: LuGem,
    label: "03",
    title: "Scratch & Win",
    desc: "After 3 blocks, scratch your card. Match 2 symbols for a small win, match 3 for the jackpot.",
    color: PURP,
  },
];

const FEATURES = [
  {
    icon: LuShieldCheck,
    title: "Provably Fair",
    desc: "Results are derived from Ethereum block hashes — verifiable by anyone, tamper-proof on-chain.",
    color: "#39FF14",
  },
  {
    icon: LuLayers,
    title: "Jackpot Grows with Every Swap",
    desc: "A custom Uniswap V4 hook diverts a slice of swap fees directly into the live prize pool.",
    color: PINK,
  },
  {
    icon: LuZap,
    title: "Auto-Reveal via Reactive Network",
    desc: "No manual steps — Reactive Network automatically triggers your card reveal after the block.",
    color: LILAC,
  },
  {
    icon: LuFlame,
    title: "Referral Rewards",
    desc: "Refer friends and earn 5% of every card they buy. Hit 10 referrals to unlock the Hustler badge.",
    color: "#FFD700",
  },
];

const STATS = [
  { label: "Card Price",   value: "0.50 USDC" },
  { label: "Small Win",    value: "0.25 USDC" },
  { label: "Referral Cut", value: "5%" },
  { label: "Reveal Delay", value: "3 Blocks" },
];

export default function Home() {
  return <LandingPage />;
}

function LandingPage() {
  const { winners } = useRecentWinners();

  return (
    <div className="relative min-h-screen bg-[#08080F] text-white overflow-x-hidden">
      <ParticleBackground />

      {/* ── NAV ─────────────────────────────────────────────────── */}
      <nav className="relative z-10 flex items-center justify-between px-6 md:px-14 py-5 border-b border-white/5">
        <div className="flex items-center gap-2.5">
          <div
            className="w-9 h-9 rounded-xl flex items-center justify-center"
            style={{ background: `linear-gradient(135deg, ${PINK}, ${PURP})` }}
          >
            <LuTicket className="w-4.5 h-4.5 text-white" />
          </div>
          <span className="font-fire text-2xl tracking-widest text-fire-sm">
            SCRATCH<span style={{ color: LILAC }}>IN&apos;</span>
          </span>
        </div>

        <div className="hidden md:flex items-center gap-8 text-sm font-semibold text-white/60">
          <a href="#how"      className="hover:text-white transition-colors">How It Works</a>
          <a href="#features" className="hover:text-white transition-colors">Features</a>
          <a href="#winners"  className="hover:text-white transition-colors">Winners</a>
        </div>

        <div className="flex items-center gap-3">
          <Link
            href="/play"
            className="hidden sm:flex items-center gap-1.5 text-sm font-bold px-4 py-2 rounded-xl border border-white/10 text-white/70 hover:text-white hover:border-white/25 transition-all"
          >
            <LuTicket className="w-3.5 h-3.5" /> Play Game
          </Link>
          <ConnectButton />
        </div>
      </nav>

      {/* ── HERO ────────────────────────────────────────────────── */}
      <section className="relative z-10 px-6 md:px-14 pt-16 pb-14 md:pt-24 md:pb-20">
        <div className="max-w-5xl mx-auto">

          {/* Live badge */}
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="mb-8 inline-flex items-center gap-2 text-xs font-bold px-4 py-1.5 rounded-full border"
            style={{ background: `${PURP}22`, borderColor: `${PURP}55`, color: LILAC }}
          >
            <span className="w-1.5 h-1.5 rounded-full bg-[#39FF14] animate-pulse" />
            Live on Unichain Sepolia
            <SiEthereum className="w-3 h-3" />
          </motion.div>

          {/* Two-column layout on md+: headline left, right panel right */}
          <div className="flex flex-col md:flex-row md:items-center gap-10 md:gap-16">

            {/* LEFT — headline only */}
            <motion.div
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.1 }}
              className="flex-1 min-w-0"
            >
              <h1 className="font-fire leading-[0.88] tracking-widest" style={{ fontSize: "clamp(3.8rem, 10vw, 8rem)" }}>
                <span className="block text-[0.38em] text-white/40 tracking-[0.35em] mb-2 font-fire">THE ON-CHAIN</span>
                <span className="block text-gradient-fire">SCRATCH</span>
                <span className="block text-gradient-fire" style={{ marginTop: "-0.08em" }}>CARD GAME</span>
              </h1>
            </motion.div>

            {/* RIGHT — subtitle, jackpot, CTA */}
            <motion.div
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.18 }}
              className="flex flex-col gap-6 md:max-w-xs lg:max-w-sm"
            >
              <p className="text-white/65 text-lg font-semibold leading-relaxed">
                Buy scratch cards with USDC. Block hash reveals your fate.
                Jackpot grows with every swap on Uniswap V4.
              </p>

              <JackpotTicker />

              <div className="flex flex-col gap-3 w-full">
                <Link
                  href="/play"
                  className="flex items-center justify-center gap-2.5 font-fire text-2xl px-10 py-3.5 rounded-2xl text-white tracking-widest transition-transform hover:scale-105 active:scale-95 w-full sm:w-auto"
                  style={{
                    background: `linear-gradient(135deg, #FF6B00, ${PINK}, ${PURP})`,
                    boxShadow: `0 0 25px ${PINK}55`,
                  }}
                >
                  <LuFlame className="w-5 h-5" />
                  PLAY NOW
                </Link>
                <a
                  href="#how"
                  className="flex items-center gap-1.5 text-white/45 hover:text-white text-sm font-semibold transition-colors self-center"
                >
                  How it works <LuArrowRight className="w-3.5 h-3.5" />
                </a>
              </div>
            </motion.div>
          </div>

          {/* Powered-by row */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.4 }}
            className="mt-12 flex flex-wrap items-center gap-7 text-xs text-white/30 font-bold uppercase tracking-widest"
          >
            <span className="flex items-center gap-2">
              <LuLayers className="w-3.5 h-3.5" style={{ color: PINK }} /> Uniswap V4
            </span>
            <span className="text-white/10">·</span>
            <span className="flex items-center gap-2">
              <LuZap className="w-3.5 h-3.5" style={{ color: LILAC }} /> Reactive Network
            </span>
            <span className="text-white/10">·</span>
            <span className="flex items-center gap-2">
              <SiEthereum className="w-3.5 h-3.5" style={{ color: PURP }} /> Unichain L2
            </span>
          </motion.div>
        </div>
      </section>

      {/* ── STATS ROW ────────────────────────────────────────────── */}
      <section className="relative z-10 border-y border-white/5 bg-white/2">
        <div className="max-w-4xl mx-auto px-6 py-10 grid grid-cols-2 md:grid-cols-4 gap-6">
          {STATS.map((s) => (
            <div key={s.label} className="text-center">
              <div className="font-fire text-4xl text-white tracking-widest text-fire-sm">{s.value}</div>
              <div className="text-xs text-white/45 mt-1 uppercase tracking-widest font-bold">{s.label}</div>
            </div>
          ))}
        </div>
      </section>

      {/* ── HOW IT WORKS ─────────────────────────────────────────── */}
      <section id="how" className="relative z-10 py-28 px-6 md:px-14">
        <div className="max-w-5xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="font-fire text-[clamp(2.5rem,6vw,5rem)] tracking-widest text-gradient-fire text-fire mb-4">
              HOW IT WORKS
            </h2>
            <p className="text-white/55 text-lg font-semibold max-w-md mx-auto">
              Three steps to winning — fully on-chain, no middleman.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-6">
            {HOW_STEPS.map((step, i) => {
              const Icon = step.icon;
              return (
                <motion.div
                  key={i}
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: i * 0.1 }}
                  className="relative bg-white/3 border border-white/8 rounded-2xl p-8 hover:border-white/20 transition-colors"
                >
                  <div
                    className="font-fire text-5xl mb-5 tracking-wide opacity-40"
                    style={{ color: step.color }}
                  >
                    {step.label}
                  </div>
                  <div
                    className="w-12 h-12 rounded-xl flex items-center justify-center mb-5"
                    style={{ background: `${step.color}22`, border: `1px solid ${step.color}44` }}
                  >
                    <Icon className="w-6 h-6" style={{ color: step.color }} />
                  </div>
                  <h3 className="font-black text-white text-xl mb-3">{step.title}</h3>
                  <p className="text-white/55 text-base font-medium leading-relaxed">{step.desc}</p>
                </motion.div>
              );
            })}
          </div>
        </div>
      </section>

      {/* ── FEATURES ─────────────────────────────────────────────── */}
      <section id="features" className="relative z-10 py-24 px-6 md:px-14 bg-white/1.5">
        <div className="max-w-5xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="font-fire text-[clamp(2.5rem,6vw,5rem)] tracking-widest text-gradient-fire text-fire mb-4">
              BUILT DIFFERENT
            </h2>
            <p className="text-white/55 text-lg font-semibold">
              Not your average lottery — every mechanic is on-chain and transparent.
            </p>
          </div>

          <div className="grid sm:grid-cols-2 gap-5">
            {FEATURES.map((f, i) => {
              const Icon = f.icon as React.ComponentType<{ className?: string; style?: React.CSSProperties }>;
              return (
                <motion.div
                  key={i}
                  initial={{ opacity: 0, y: 16 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: i * 0.08 }}
                  className="flex gap-5 bg-white/3 border border-white/8 rounded-2xl p-7 hover:border-white/20 transition-colors"
                >
                  <div
                    className="w-12 h-12 rounded-xl flex items-center justify-center shrink-0"
                    style={{ background: `${f.color}20`, border: `1px solid ${f.color}40` }}
                  >
                    <Icon className="w-6 h-6" style={{ color: f.color }} />
                  </div>
                  <div>
                    <h3 className="font-black text-white text-lg mb-2">{f.title}</h3>
                    <p className="text-white/55 text-base font-medium leading-relaxed">{f.desc}</p>
                  </div>
                </motion.div>
              );
            })}
          </div>
        </div>
      </section>

      {/* ── RECENT WINNERS ───────────────────────────────────────── */}
      <section id="winners" className="relative z-10 py-24 px-6 md:px-14">
        <div className="max-w-3xl mx-auto">
          <div className="text-center mb-12">
            <h2 className="font-fire text-[clamp(2.5rem,6vw,5rem)] tracking-widest text-gradient-fire text-fire mb-4">
              RECENT WINNERS
            </h2>
            <p className="text-white/55 text-lg font-semibold">Live from the blockchain.</p>
          </div>

          <div className="space-y-3">
            {(winners.length > 0 ? winners.slice(0, 8) : [
              { address: "0xAb12...F3c1", prize: "12.50 USDC", ago: "2m ago" },
              { address: "0xDe34...A8b2", prize: "0.25 USDC",  ago: "5m ago" },
              { address: "0x7890...C4d3", prize: "0.25 USDC",  ago: "8m ago" },
            ]).map((w, i) => (
              <WinnerRow key={i} rank={i + 1} address={w.address} prize={w.prize} ago={w.ago} />
            ))}
          </div>

          <div className="text-center mt-12">
            <Link
              href="/play"
              className="inline-flex items-center gap-2 font-bold text-base px-8 py-4 rounded-xl border transition-all hover:scale-105"
              style={{ borderColor: `${PINK}55`, color: PINK, background: `${PINK}11` }}
            >
              <LuTicket className="w-4 h-4" />
              Be the next winner
            </Link>
          </div>
        </div>
      </section>

      {/* ── LEADERBOARD PREVIEW ──────────────────────────────────── */}
      <section className="relative z-10 py-20 px-6 md:px-14 bg-white/1.5">
        <div className="max-w-3xl mx-auto">
          <div className="flex items-center justify-between mb-10">
            <h2 className="font-fire text-4xl tracking-widest" style={{
              background: `linear-gradient(135deg, #FFD700, ${PINK})`,
              WebkitBackgroundClip: "text",
              WebkitTextFillColor: "transparent",
              backgroundClip: "text",
              textShadow: "none",
            }}>
              THIS WEEK&apos;S KINGS
            </h2>
            <Link
              href="/play"
              className="text-sm font-bold flex items-center gap-1.5 hover:text-white transition-colors"
              style={{ color: LILAC }}
            >
              Full leaderboard <LuArrowRight className="w-3.5 h-3.5" />
            </Link>
          </div>

          <div className="space-y-3">
            {[
              { label: "👑", address: "0xAb12...F3c1", value: "12 wins", icon: LuCrown  },
              { label: "🥈", address: "0xDe34...A8b2", value: "9 wins",  icon: FaTrophy },
              { label: "🥉", address: "0x7890...C4d3", value: "7 wins",  icon: FaMedal  },
            ].map((row, i) => (
              <div
                key={i}
                className="flex items-center gap-4 bg-white/3 border border-white/8 rounded-xl px-5 py-4"
              >
                <span className="text-xl w-8 text-center">{row.label}</span>
                <span className="font-mono text-white/70 text-sm flex-1">{row.address}</span>
                <span className="font-black text-base" style={{ color: LILAC }}>{row.value}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── FOOTER ───────────────────────────────────────────────── */}
      <footer className="relative z-10 border-t border-white/8 bg-black/40">
        <div className="max-w-6xl mx-auto px-6 md:px-14 py-16">
          <div className="grid md:grid-cols-4 gap-10 mb-12">

            {/* Brand */}
            <div className="md:col-span-2">
              <div className="flex items-center gap-3 mb-5">
                <div
                  className="w-10 h-10 rounded-xl flex items-center justify-center"
                  style={{ background: `linear-gradient(135deg, #FF6B00, ${PINK}, ${PURP})` }}
                >
                  <LuTicket className="w-5 h-5 text-white" />
                </div>
                <span className="font-fire text-4xl tracking-widest text-fire-sm">
                  SCRATCH<span style={{ color: LILAC }}>IN&apos;</span>
                </span>
              </div>
              <p className="text-white/50 text-base font-semibold leading-relaxed max-w-sm mb-6">
                The world&apos;s first on-chain scratch card game. Fully transparent,
                provably fair, and automatically revealed by Reactive Network.
              </p>
              <Link
                href="/play"
                className="inline-flex items-center gap-2 font-fire text-2xl px-8 py-3 rounded-xl text-white tracking-widest transition-transform hover:scale-105"
                style={{
                  background: `linear-gradient(135deg, #FF6B00, ${PINK}, ${PURP})`,
                  boxShadow: `0 0 25px ${PINK}44`,
                }}
              >
                PLAY NOW <LuArrowRight className="w-5 h-5" />
              </Link>
            </div>

            {/* Game links */}
            <div>
              <div className="font-fire text-xl tracking-widest text-white/70 mb-5 text-fire-sm">GAME</div>
              <ul className="space-y-3 text-base text-white/55 font-semibold">
                <li><a href="#how"      className="hover:text-white transition-colors">How It Works</a></li>
                <li><a href="#features" className="hover:text-white transition-colors">Features</a></li>
                <li><a href="#winners"  className="hover:text-white transition-colors">Recent Winners</a></li>
                <li><Link href="/play"  className="hover:text-white transition-colors">Play Now</Link></li>
              </ul>
            </div>

            {/* Powered by */}
            <div>
              <div className="font-fire text-xl tracking-widest text-white/70 mb-5 text-fire-sm">POWERED BY</div>
              <ul className="space-y-3 text-base text-white/55 font-semibold">
                <li className="flex items-center gap-2.5">
                  <LuLayers className="w-4 h-4 shrink-0" style={{ color: PINK }} />
                  Uniswap V4 Hooks
                </li>
                <li className="flex items-center gap-2.5">
                  <LuZap className="w-4 h-4 shrink-0" style={{ color: LILAC }} />
                  Reactive Network
                </li>
                <li className="flex items-center gap-2.5">
                  <SiEthereum className="w-4 h-4 shrink-0" style={{ color: PURP }} />
                  Unichain L2
                </li>
                <li className="flex items-center gap-2.5">
                  <LuShieldCheck className="w-4 h-4 shrink-0" style={{ color: "#39FF14" }} />
                  Provably Fair
                </li>
              </ul>
            </div>
          </div>

          {/* Bottom bar */}
          <div className="border-t border-white/8 pt-8 flex flex-col md:flex-row items-center justify-between gap-4">
            <div className="flex items-center gap-3">
              <span className="font-fire text-xl tracking-widest text-fire-sm" style={{ color: PINK }}>
                SCRATCHIN&apos;
              </span>
              <span className="text-sm text-white/40 font-semibold">© 2025 All rights reserved.</span>
            </div>
            <div className="flex flex-wrap items-center justify-center gap-4 text-sm text-white/35 font-semibold text-center">
              <span>Smart contracts on Unichain Sepolia</span>
              <span className="text-white/15">·</span>
              <span>Provably fair via block hash</span>
              <span className="text-white/15">·</span>
              <span>Not financial advice</span>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}

function WinnerRow({
  rank, address, prize, ago,
}: {
  rank: number; address: string; prize: string; ago: string;
}) {
  const medals = ["🥇", "🥈", "🥉"];
  return (
    <motion.div
      initial={{ opacity: 0, x: -12 }}
      whileInView={{ opacity: 1, x: 0 }}
      viewport={{ once: true }}
      transition={{ delay: rank * 0.05 }}
      className="flex items-center gap-4 bg-white/3 border border-white/8 rounded-xl px-5 py-4 hover:border-white/20 transition-colors"
    >
      <span className="text-xl w-8 text-center">{medals[rank - 1] ?? `#${rank}`}</span>
      <span className="font-mono text-white text-sm flex-1 font-semibold">{address}</span>
      <span className="font-black text-base" style={{ color: "#FC72FF" }}>{prize}</span>
      <span className="text-white/35 text-sm font-semibold">{ago}</span>
    </motion.div>
  );
}
