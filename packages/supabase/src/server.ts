import { createServerClient, type CookieOptions } from "@supabase/ssr";

import { getSupabaseConfig } from "./env";
import type { Database } from "./database.types";

interface CookieToSet {
  name: string;
  value: string;
  options: CookieOptions;
}

export interface ServerCookieStore {
  getAll(): { name: string; value: string }[];

  set(name: string, value: string, options: CookieOptions): void;
}

export function createSupabaseServerClient(cookieStore: ServerCookieStore) {
  const { url, publishableKey } = getSupabaseConfig();

  return createServerClient<Database>(url, publishableKey, {
    cookies: {
      getAll() {
        return cookieStore.getAll();
      },

      setAll(cookiesToSet: CookieToSet[]) {
        try {
          cookiesToSet.forEach(({ name, value, options }) => {
            cookieStore.set(name, value, options);
          });
        } catch {
          // Server Components cannot write cookies.
          // Session refresh is handled by the app's proxy.
        }
      },
    },
  });
}
