import type { Metadata } from "next";
import type { CSSProperties, ReactNode } from "react";
import { DM_Sans, Instrument_Serif, IBM_Plex_Mono } from "next/font/google";

import { Providers } from "@/providers/providers";
import "./globals.css";

const bodyFont = DM_Sans({
  variable: "--font-body",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
});

const headingFont = Instrument_Serif({
  variable: "--font-heading",
  subsets: ["latin"],
  weight: "400",
});

const monoFont = IBM_Plex_Mono({
  variable: "--font-mono",
  subsets: ["latin"],
  weight: ["400", "500"],
});

export const metadata: Metadata = {
  title: {
    default: "Shopverse — Discover something good",
    template: "%s | Shopverse",
  },
  description: "Discover great products from independent vendors on Shopverse.",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html
      lang="en"
      className="kui-scrollbar"
      style={
        {
          "--font-body": bodyFont.style.fontFamily,
          "--font-heading": headingFont.style.fontFamily,
          "--font-mono": monoFont.style.fontFamily,
        } as CSSProperties
      }
    >
      <body className="min-h-screen flex flex-col">
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
