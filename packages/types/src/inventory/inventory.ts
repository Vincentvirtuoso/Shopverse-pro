import type { EntityId, VendorId } from "../shared/identifiers.js";

export type InventoryTrackingMode = "manual" | "hybrid";

export type InventoryLocationType =
  "warehouse" | "store" | "fulfillment_center" | "other";

export type InventoryLocationOwnership =
  | {
      ownerType: "platform";
      vendorId: null;
    }
  | {
      ownerType: "vendor";
      vendorId: VendorId;
    };

export type InventoryLocation = InventoryLocationOwnership & {
  id: EntityId<"inventory-location">;
  name: string;
  code: string;
  type: InventoryLocationType;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
};

export interface InventoryLevel {
  id: EntityId<"inventory-level">;

  /** Inventory is tracked against a specific product variant. */
  variantId: EntityId<"product-variant">;

  /** The location must belong to the same owner as the product. */
  locationId: EntityId<"inventory-location">;

  /** Must be a non-negative integer. */
  onHandQuantity: number;

  /** Must be non-negative and cannot exceed onHandQuantity. */
  reservedQuantity: number;

  trackingMode: InventoryTrackingMode;

  updatedAt: string;
}

export type InventoryAdjustmentReason =
  "restock" | "sale" | "return" | "damage" | "correction";

export interface InventoryAdjustment {
  id: EntityId<"inventory-adjustment">;
  inventoryLevelId: EntityId<"inventory-level">;

  /** Signed quantity change. */
  quantityChange: number;

  reason: InventoryAdjustmentReason;

  referenceId: string | null;
  note: string | null;

  createdAt: string;
}
