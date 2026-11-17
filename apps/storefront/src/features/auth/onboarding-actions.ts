"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export type OnboardingActionState = {
  status: "error";
  message: string;
} | null;

export async function completeOnboardingAction(
  _previousState: OnboardingActionState,
  formData: FormData,
): Promise<OnboardingActionState> {
  const supabase = await createClient();

  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser();

  if (authError || !user) {
    redirect("/login");
  }

  const phone = String(formData.get("phone") ?? "").trim();
  const preferredCurrency = String(
    formData.get("preferredCurrency") ?? "",
  ).trim();
  const preferredLocale = String(formData.get("preferredLocale") ?? "").trim();

  const categoryIds = [
    ...new Set(formData.getAll("categoryIds").map(String).filter(Boolean)),
  ];

  const address = {
    first_name: String(formData.get("firstName") ?? "").trim(),
    last_name: String(formData.get("lastName") ?? "").trim(),
    address_line_1: String(formData.get("addressLine1") ?? "").trim(),
    address_line_2: String(formData.get("addressLine2") ?? "").trim(),
    city: String(formData.get("city") ?? "").trim(),
    state: String(formData.get("state") ?? "").trim(),
    postal_code: String(formData.get("postalCode") ?? "").trim(),
    country_code: String(formData.get("countryCode") ?? "")
      .trim()
      .toUpperCase(),
    phone,
  };

  const hasAddress = Object.values(address).some(Boolean);

  if (
    hasAddress &&
    (!address.first_name ||
      !address.last_name ||
      !address.address_line_1 ||
      !address.city ||
      !/^[A-Z]{2}$/.test(address.country_code))
  ) {
    return {
      status: "error",
      message:
        "Complete the required delivery address fields or leave the address section empty.",
    };
  }

  const { error: profileError } = await supabase
    .from("customer_profiles")
    .update({
      phone: phone || null,
      preferred_currency: preferredCurrency || "USD",
      preferred_locale: preferredLocale || "en",
      onboarding_completed_at: new Date().toISOString(),
    })
    .eq("user_id", user.id);

  if (profileError) {
    return {
      status: "error",
      message: "We couldn't save your profile. Please try again.",
    };
  }

  if (hasAddress) {
    const { error } = await supabase.from("customer_addresses").insert({
      user_id: user.id,
      first_name: address.first_name,
      last_name: address.last_name,
      address_line_1: address.address_line_1,
      address_line_2: address.address_line_2 || null,
      city: address.city,
      state: address.state || null,
      postal_code: address.postal_code || null,
      country_code: address.country_code,
      phone: address.phone || null,
      is_default_shipping: true,
      is_default_billing: false,
    });

    if (error) {
      return {
        status: "error",
        message:
          "Your profile was saved, but we couldn't save the delivery address.",
      };
    }
  }

  if (categoryIds.length > 0) {
    const { error } = await supabase
      .from("customer_category_preferences")
      .upsert(
        categoryIds.map((categoryId) => ({
          user_id: user.id,
          category_id: categoryId,
        })),
        { onConflict: "user_id,category_id" },
      );

    if (error) {
      return {
        status: "error",
        message:
          "Your profile was saved, but we couldn't save your shopping interests.",
      };
    }
  }

  redirect("/");
}

export async function skipOnboardingAction() {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/login");

  const { error } = await supabase
    .from("customer_profiles")
    .update({
      onboarding_completed_at: new Date().toISOString(),
    })
    .eq("user_id", user.id);

  if (error) {
    redirect("/onboarding?error=skip");
  }

  redirect("/");
}
