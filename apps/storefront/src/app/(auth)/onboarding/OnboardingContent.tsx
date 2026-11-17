import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { OnboardingForm } from "@/features/auth/components/OnboardingForm";

export async function OnboardingContent() {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  const { data: profile } = await supabase
    .from("customer_profiles")
    .select("onboarding_completed_at")
    .eq("user_id", user.id)
    .maybeSingle();

  if (profile?.onboarding_completed_at) {
    redirect("/");
  }

  const { data: categories, error } = await supabase
    .from("categories")
    .select("id, name, slug")
    .eq("status", "active")
    .order("position", { ascending: true });

  if (error) {
    console.error("Failed to load onboarding categories:", error);
  }

  return (
    <OnboardingForm
      displayName={
        typeof user.user_metadata?.display_name === "string"
          ? user.user_metadata.display_name
          : ""
      }
      categories={categories ?? []}
    />
  );
}