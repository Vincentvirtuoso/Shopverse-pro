import type {
  CheckoutId,
  EntityId,
  ProductId,
  UserId,
  VendorId,
  OrderId,
} from "../shared/identifiers.js";

import type { CurrencyCode, Money } from "../shared/money.js";
import type {
  OrderAddressSnapshot,
  OrderItemSnapshot,
} from "./order.js";

export type CheckoutStatus =
  "active" | "processing" | "completed" | "expired" | "cancelled";

export interface CheckoutItem {
  id: EntityId<"checkout-item">;
  checkoutId: CheckoutId;

  productId: ProductId;
  variantId: EntityId<"product-variant">;

  /** Historical ownership at checkout time. */
  vendorId: VendorId | null;

  snapshot: OrderItemSnapshot;

  quantity: number;

  unitPrice: Money;
  discountAmount: Money;
  subtotal: Money;

  createdAt: string;
  updatedAt: string;
}

export interface Checkout {
  id: CheckoutId;
  userId: UserId;

  status: CheckoutStatus;
  currency: CurrencyCode;

  items: CheckoutItem[];

  subtotal: Money;
  discountTotal: Money;
  shippingTotal: Money;
  taxTotal: Money;
  grandTotal: Money;

  shippingAddress: OrderAddressSnapshot | null;
  billingAddress: OrderAddressSnapshot | null;

  orderId: OrderId | null;

  expiresAt: string;
  completedAt: string | null;

  createdAt: string;
  updatedAt: string;
}
