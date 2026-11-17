import type { EntityId, FulfillmentId } from "../shared/identifiers.js";

export type ShipmentStatus =
  | "pending"
  | "label_created"
  | "in_transit"
  | "out_for_delivery"
  | "delivered"
  | "exception"
  | "returned";

export interface ShipmentTrackingEvent {
  id: EntityId<"tracking-event">;
  status: ShipmentStatus;
  description: string;
  location: string | null;
  occurredAt: string;
}

export interface Shipment {
  id: EntityId<"shipment">;
  fulfillmentId: FulfillmentId;

  carrier: string | null;
  trackingNumber: string | null;
  trackingUrl: string | null;

  status: ShipmentStatus;
  events: ShipmentTrackingEvent[];

  shippedAt: string | null;
  deliveredAt: string | null;

  createdAt: string;
  updatedAt: string;
}
