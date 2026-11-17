import type {
  OrderId,
  OrderItemId,
  ReturnId,
  ReturnItemId,
  UserId,
} from "../shared/identifiers.js";

export type ReturnStatus =
  | "requested"
  | "approved"
  | "rejected"
  | "awaiting_shipment"
  | "in_transit"
  | "received"
  | "inspecting"
  | "completed"
  | "cancelled";

export type ReturnReason =
  | "damaged"
  | "defective"
  | "wrong_item"
  | "missing_parts"
  | "not_as_described"
  | "wrong_size"
  | "changed_mind"
  | "other";

export type ReturnResolution = "refund" | "replacement" | "no_refund";

export interface ReturnItem {
  id: ReturnItemId;
  returnId: ReturnId;
  orderItemId: OrderItemId;

  /** Quantity the customer wants to return. */
  requestedQuantity: number;

  /** Quantity approved by the platform. */
  approvedQuantity: number | null;

  reason: ReturnReason;
  reasonDetails: string | null;

  resolution: ReturnResolution | null;
  resolutionNotes: string | null;

  createdAt: string;
  updatedAt: string;
}

export interface Return {
  id: ReturnId;
  returnNumber: string;

  orderId: OrderId;
  customerId: UserId;

  status: ReturnStatus;
  items: ReturnItem[];

  customerNotes: string | null;
  reviewNotes: string | null;

  requestedAt: string;
  reviewedAt: string | null;
  receivedAt: string | null;
  resolvedAt: string | null;

  createdAt: string;
  updatedAt: string;
}
