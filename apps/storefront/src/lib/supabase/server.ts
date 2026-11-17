import { cookies } from "next/headers";
import { createSupabaseServerClient } from "@shopverse/supabase/server";

export async function createClient() {
  const cookieStore = await cookies();

  return createSupabaseServerClient(cookieStore);
}
