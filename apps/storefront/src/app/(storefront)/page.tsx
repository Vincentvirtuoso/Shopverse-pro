import type { Metadata } from "next";
import { HomePageClient } from "../_components/HomePageClient";

export const metadata: Metadata = {
  title: "Shopverse — Good things. Great finds.",
  description:
    "Discover thoughtfully selected products from vendors worth knowing. Find your next favourite thing.",
};

export default function HomePage() {
  return <HomePageClient />;
}
