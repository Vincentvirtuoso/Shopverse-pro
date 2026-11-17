import type { EntityId, UserId, VendorId } from "../shared/identifiers.js";
import type { Money } from "../shared/money.js";

export type VendorPayoutStatus =
  "pending" | "processing" | "succeeded" | "failed" | "cancelled";

export interface VendorPayoutItem {
  id: EntityId<"vendor-payout-item">;
  payoutId: EntityId<"vendor-payout">;
  earningId: EntityId<"vendor-earning">;

  amount: Money;
  createdAt: string;
}

export interface VendorPayout {
  id: EntityId<"vendor-payout">;
  vendorId: VendorId;

  amount: Money;
  currency: string;

  status: VendorPayoutStatus;

  provider: string | null;
  providerReference: string | null;
  idempotencyKey: string;

  failureReason: string | null;

  requestedAt: string;
  processedAt: string | null;
  completedAt: string | null;

  createdAt: string;
  updatedAt: string;

  items: VendorPayoutItem[];
}
