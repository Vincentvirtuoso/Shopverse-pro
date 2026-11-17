"use client";

import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from "react";

type ChromeContextValue = {
  announcementHeight: number;
  headerHeight: number;
  totalHeaderHeight: number;
  setAnnouncementHeight: (height: number) => void;
  setHeaderHeight: (height: number) => void;
};

const StorefrontChromeContext = createContext<ChromeContextValue | null>(null);

export function StorefrontChromeProvider({
  children,
}: {
  children: ReactNode;
}) {
  const [announcementHeight, setAnnouncementHeightState] = useState(0);
  const [headerHeight, setHeaderHeightState] = useState(0);

  const setAnnouncementHeight = useCallback((height: number) => {
    setAnnouncementHeightState((current) =>
      current === height ? current : height,
    );
  }, []);

  const setHeaderHeight = useCallback((height: number) => {
    setHeaderHeightState((current) => (current === height ? current : height));
  }, []);

  const value = useMemo(
    () => ({
      announcementHeight,
      headerHeight,
      totalHeaderHeight: announcementHeight + headerHeight,
      setAnnouncementHeight,
      setHeaderHeight,
    }),
    [announcementHeight, headerHeight, setAnnouncementHeight, setHeaderHeight],
  );

  return (
    <StorefrontChromeContext.Provider value={value}>
      {children}
    </StorefrontChromeContext.Provider>
  );
}

export function useStorefrontChrome() {
  const context = useContext(StorefrontChromeContext);

  if (!context) {
    throw new Error(
      "useStorefrontChrome must be used inside StorefrontChromeProvider",
    );
  }

  return context;
}
