import type {
  CheckoutId,
  EntityId,
  InventoryReservationId,
  InventoryReservationItemId,
} from "../shared/identifiers.js";

export type InventoryReservationStatus =
  "active" | "committed" | "released" | "expired";

export interface InventoryReservationItem {
  id: InventoryReservationItemId;
  reservationId: InventoryReservationId;
  inventoryLevelId: EntityId<"inventory-level">;
  quantity: number;
}

export interface InventoryReservation {
  id: InventoryReservationId;
  checkoutId: CheckoutId;
  status: InventoryReservationStatus;
  items: InventoryReservationItem[];
  expiresAt: string;
  createdAt: string;
  updatedAt: string;
}
