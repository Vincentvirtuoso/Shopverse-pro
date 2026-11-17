import type {
  CategoryId,
  EntityId,
  OrderItemId,
  VendorId,
} from "../shared/identifiers.js";
import type { Money } from "../shared/money.js";

export type CommissionRateSource =
  "platform_default" | "category_override" | "vendor_override";

export interface CommissionPolicy {
  id: EntityId<"commission-policy">;

  /** Basis points: 1000 = 10%. */
  defaultRateBasisPoints: number;

  /** Additional rate when Shopverse handles logistics. */
  logisticsRateBasisPoints: number;

  isActive: boolean;
  effectiveFrom: string;
  effectiveUntil: string | null;

  createdAt: string;
  updatedAt: string;
}

export interface CategoryCommissionOverride {
  id: EntityId<"category-commission-override">;
  categoryId: CategoryId;
  rateBasisPoints: number;

  effectiveFrom: string;
  effectiveUntil: string | null;

  createdAt: string;
  updatedAt: string;
}

export interface VendorCommissionOverride {
  id: EntityId<"vendor-commission-override">;
  vendorId: VendorId;
  rateBasisPoints: number;

  effectiveFrom: string;
  effectiveUntil: string | null;

  createdAt: string;
  updatedAt: string;
}

export interface OrderItemCommissionSnapshot {
  id: EntityId<"order-item-commission">;
  orderItemId: OrderItemId;

  productSubtotal: Money;

  standardRateBasisPoints: number;
  standardRateSource: CommissionRateSource;
  standardCommissionAmount: Money;

  logisticsApplied: boolean;
  logisticsRateBasisPoints: number;
  logisticsCommissionAmount: Money;

  totalCommissionAmount: Money;
  vendorNetAmount: Money;

  createdAt: string;
}
