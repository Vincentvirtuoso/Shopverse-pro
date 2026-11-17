"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { useRouter } from "next/navigation";

interface SearchContextValue {
  isOpen: boolean;
  query: string;
  recentSearches: string[];
  openSearch: () => void;
  closeSearch: () => void;
  toggleSearch: () => void;
  setQuery: (query: string) => void;
  submitSearch: (query?: string) => void;
  clearRecentSearches: () => void;
}

const STORAGE_KEY = "shopverse:recent-searches";
const MAX_RECENT = 5;

const SearchContext = createContext<SearchContextValue | null>(null);

function readRecentSearches(): string[] {
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];

    const parsed: unknown = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];

    return parsed
      .filter((item): item is string => typeof item === "string")
      .slice(0, MAX_RECENT);
  } catch {
    return [];
  }
}

export function SearchProvider({ children }: { children: ReactNode }) {
  const router = useRouter();
  const [isOpen, setIsOpen] = useState(false);
  const [query, setQueryState] = useState("");
  const [recentSearches, setRecentSearches] = useState<string[]>([]);
  const [hydrated, setHydrated] = useState(false);

  // Load once after mount (avoids SSR hydration mismatch)
  useEffect(() => {
    setRecentSearches(readRecentSearches());
    setHydrated(true);
  }, []);

  // Persist on change, but only after the initial load
  useEffect(() => {
    if (!hydrated) return;

    try {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify(recentSearches));
    } catch {
      // Storage unavailable or full: keep working in memory
    }
  }, [recentSearches, hydrated]);

  // Sync across tabs
  useEffect(() => {
    const handleStorage = (event: StorageEvent) => {
      if (event.key !== null && event.key !== STORAGE_KEY) return;

      const next = readRecentSearches();
      setRecentSearches((current) =>
        JSON.stringify(current) === JSON.stringify(next) ? current : next,
      );
    };

    window.addEventListener("storage", handleStorage);
    return () => window.removeEventListener("storage", handleStorage);
  }, []);

  const openSearch = useCallback(() => setIsOpen(true), []);
  const closeSearch = useCallback(() => setIsOpen(false), []);

  const toggleSearch = useCallback(() => {
    setIsOpen((current) => !current);
  }, []);

  const setQuery = useCallback((value: string) => {
    setQueryState(value);
  }, []);

  const submitSearch = useCallback(
    (value?: string) => {
      const normalized = (value ?? query).trim();

      if (!normalized) return;

      setRecentSearches((current) =>
        [
          normalized,
          ...current.filter(
            (item) => item.toLowerCase() !== normalized.toLowerCase(),
          ),
        ].slice(0, MAX_RECENT),
      );

      setQueryState(normalized);
      setIsOpen(false);

      router.push(`/search?q=${encodeURIComponent(normalized)}`);
    },
    [query, router],
  );

  const clearRecentSearches = useCallback(() => {
    setRecentSearches([]);
  }, []);

  const contextValue = useMemo(
    () => ({
      isOpen,
      query,
      recentSearches,
      openSearch,
      closeSearch,
      toggleSearch,
      setQuery,
      submitSearch,
      clearRecentSearches,
    }),
    [
      isOpen,
      query,
      recentSearches,
      openSearch,
      closeSearch,
      toggleSearch,
      setQuery,
      submitSearch,
      clearRecentSearches,
    ],
  );

  return (
    <SearchContext.Provider value={contextValue}>
      {children}
    </SearchContext.Provider>
  );
}

export function useSearch() {
  const context = useContext(SearchContext);

  if (!context) {
    throw new Error("useSearch must be used within SearchProvider");
  }

  return context;
}
