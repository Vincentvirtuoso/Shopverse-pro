"use client";

import type { ReactNode } from "react";
import { SearchDialog } from "@/features/search/components/SearchDialog";
import { AnnouncementBar } from "../storefront/AnnouncementBar";
import { StorefrontFooter } from "../storefront/StorefrontFooter";
import { StorefrontHeader } from "../storefront/StorefrontHeader";

interface AppShellProps {
  children: ReactNode;
}

export function AppShell({ children }: AppShellProps) {
  return (
    <>
      <AnnouncementBar />

      <StorefrontHeader />

      <main className="min-h-screen">{children}</main>

      <StorefrontFooter />

      <SearchDialog />
    </>
  );
}
