import type {
  ProductDiscountId,
  ProductId,
  ProductVariantId,
  UserId,
} from "../shared/identifiers.js";

import type { Money } from "../shared/money.js";

export type ProductDiscountStatus =
  "draft" | "scheduled" | "active" | "expired" | "disabled";

export type ProductDiscountValue =
  | {
      discountType: "percentage";
      discountValue: number;
    }
  | {
      discountType: "fixed_amount";
      discountValue: Money;
    };

export interface ProductDiscount {
  id: ProductDiscountId;

  productId: ProductId;

  /**
   * Null applies to all variants.
   * Otherwise, the discount applies only to this variant.
   */
  variantId: ProductVariantId | null;

  discount: ProductDiscountValue;

  status: ProductDiscountStatus;

  startsAt: string | null;
  endsAt: string | null;

  /** User who created the discount. */
  createdBy: UserId;

  createdAt: string;
  updatedAt: string;
}
