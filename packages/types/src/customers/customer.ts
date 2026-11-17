import type { UserId } from "../shared/identifiers.js";
import { CurrencyCode } from "../shared/money.js";

export interface CustomerProfile {
  userId: UserId;
  phone: string | null;
  marketingEmailsEnabled: boolean;
  preferredCurrency: CurrencyCode | null;
  preferredLocale: string | null;
  createdAt: string;
  updatedAt: string;
}
