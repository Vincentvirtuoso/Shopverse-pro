"use client";

import { type ReactNode } from "react";
import { KreativUIProvider } from "@splenddev/kreativ-ui";

import "@splenddev/kreativ-ui/styles.css";

import { shopverseTheme } from "@/theme";

interface UIProviderProps {
  children: ReactNode;
}

export function UIProvider({ children }: UIProviderProps) {
  return (
    <KreativUIProvider
      theme={shopverseTheme}
      defaultMode="light"
      persistMode={false}
    >
      {children}
    </KreativUIProvider>
  );
}
