import type {
  EntityId,
  OrderId,
  OrderItemId,
  ProductId,
  UserId,
  VendorId,
} from "../shared/identifiers.js";

import type { CurrencyCode, Money } from "../shared/money.js";

export type OrderStatus =
  | "pending_payment"
  | "paid"
  | "processing"
  | "partially_fulfilled"
  | "fulfilled"
  | "cancelled"
  | "refunded"
  | "partially_refunded";

export interface OrderAddressSnapshot {
  firstName: string;
  lastName: string;
  company: string | null;
  addressLine1: string;
  addressLine2: string | null;
  city: string;
  state: string | null;
  postalCode: string | null;
  countryCode: string;
  phone: string | null;
}

export interface OrderItemSnapshot {
  productName: string;
  productSlug: string;
  variantName: string;
  sku: string | null;
  imageUrl: string | null;
}

export interface OrderItem {
  id: OrderItemId;
  orderId: OrderId;
  productId: ProductId;
  variantId: EntityId<"product-variant">;

  /**
   * Historical product ownership at purchase time.
   * Null means the product was platform-owned.
   */
  vendorId: VendorId | null;

  snapshot: OrderItemSnapshot;

  /** Must be a positive integer. */
  quantity: number;

  /** Price per unit at purchase time. */
  unitPrice: Money;

  /** Historical line subtotal at purchase time. */
  subtotal: Money;
}

export interface Order {
  id: OrderId;
  orderNumber: string;
  customerId: UserId;

  status: OrderStatus;
  currency: CurrencyCode;

  items: OrderItem[];

  subtotal: Money;
  discountTotal: Money;
  shippingTotal: Money;
  taxTotal: Money;
  grandTotal: Money;

  shippingAddress: OrderAddressSnapshot | null;
  billingAddress: OrderAddressSnapshot | null;

  placedAt: string | null;
  paidAt: string | null;

  createdAt: string;
  updatedAt: string;
}
