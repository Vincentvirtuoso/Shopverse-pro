import { createSupabaseBrowserClient } from "@shopverse/supabase/client";
import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "@shopverse/supabase/database.types";

let browserClient: SupabaseClient<Database> | undefined;

export function createClient(): SupabaseClient<Database> {
  browserClient ??= createSupabaseBrowserClient();

  return browserClient;
}
