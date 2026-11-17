import type { EntityId, UserId, VendorId } from "../shared/identifiers.js";

export type PayoutAccountStatus =
  "pending_verification" | "verified" | "rejected" | "disabled";

export interface VendorPayoutAccount {
  id: EntityId<"vendor-payout-account">;
  vendorId: VendorId;

  /** Bank or payout provider identifier. */
  provider: string;
  providerAccountId: string | null;

  /** Bank details returned by the provider. */
  accountName: string;
  accountNumberLast4: string;
  bankCode: string;
  bankName: string;

  currency: string;
  countryCode: string;

  status: PayoutAccountStatus;
  isDefault: boolean;

  verifiedAt: string | null;
  createdBy: UserId;

  createdAt: string;
  updatedAt: string;
}
