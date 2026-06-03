import type { Metadata } from "next";
import { Geist, Geist_Mono, Bangers } from "next/font/google";
import { Providers } from "@/components/Providers";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

// Bangers: the bold condensed game/comic font — wide letter-spacing, maximum impact
const bangers = Bangers({
  variable: "--font-fire",
  subsets: ["latin"],
  weight: "400",
});

export const metadata: Metadata = {
  title: "SCRATCHIN' — On-Chain Scratch Card Game",
  description: "Scratch. Win. Repeat. On-chain forever. Powered by Uniswap V4 · Reactive Network · Unichain.",
  openGraph: {
    title: "SCRATCHIN'",
    description: "The world's first on-chain scratch card game.",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      className={`${geistSans.variable} ${geistMono.variable} ${bangers.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col bg-[#08080F] text-white">
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
