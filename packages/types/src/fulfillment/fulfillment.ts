import type {
  FulfillmentId,
  FulfillmentItemId,
  OrderId,
  OrderItemId,
  SupplierId,
  VendorId,
} from "../shared/identifiers.js";

export type FulfillmentStatus =
  | "pending"
  | "awaiting_supplier"
  | "processing"
  | "shipped"
  | "delivered"
  | "failed"
  | "cancelled";

export type FulfillmentSource =
  | {
      type: "platform";
      vendorId: null;
      supplierId: SupplierId | null;
    }
  | {
      type: "vendor";
      vendorId: VendorId;
      supplierId: SupplierId | null;
    };

export interface FulfillmentItem {
  id: FulfillmentItemId;
  orderItemId: OrderItemId;
  quantity: number;
}

export type Fulfillment = FulfillmentSource & {
  id: FulfillmentId;
  orderId: OrderId;

  status: FulfillmentStatus;
  items: FulfillmentItem[];

  externalOrderReference: string | null;

  createdAt: string;
  updatedAt: string;
};
