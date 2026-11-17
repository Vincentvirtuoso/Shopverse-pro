import type { EntityId, ProductId, VendorId } from "../shared/identifiers.js";

import type { Money } from "../shared/money.js";

export type PromotionStatus =
  "draft" | "scheduled" | "active" | "expired" | "disabled";

export type PromotionOwnership =
  | {
      ownerType: "platform";
      vendorId: null;
    }
  | {
      ownerType: "vendor";
      vendorId: VendorId;
    };

export type PromotionDiscount =
  | {
      discountType: "percentage";
      discountValue: number;
    }
  | {
      discountType: "fixed_amount";
      discountValue: Money;
    };

export type Promotion = PromotionOwnership &
  PromotionDiscount & {
    id: EntityId<"promotion">;

    name: string;
    code: string | null;
    description: string | null;

    minimumOrderAmount: Money | null;
    maximumDiscountAmount: Money | null;

    applicableProductIds: ProductId[];

    usageLimit: number | null;
    usageCount: number;

    startsAt: string | null;
    endsAt: string | null;

    status: PromotionStatus;

    createdAt: string;
    updatedAt: string;
  };
