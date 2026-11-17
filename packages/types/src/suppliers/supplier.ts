import type { Money } from "../shared/money.js";

import type {
  SupplierId,
  SupplierProductId,
  SupplierProductVariantId,
  ProductSupplierSourceId,
  EntityId,
  VendorId,
} from "../shared/identifiers.js";

export type SupplierProvider = "aliexpress" | "alibaba" | "custom";

export type SupplierStatus =
  "pending" | "connected" | "disconnected" | "suspended";

export type SupplierProductStatus =
  "available" | "unavailable" | "discontinued" | "unknown";

export type SupplierOwnership =
  | {
      ownerType: "platform";
      vendorId: null;
    }
  | {
      ownerType: "vendor";
      vendorId: VendorId;
    };

export type Supplier = SupplierOwnership & {
  id: SupplierId;
  name: string;
  provider: SupplierProvider;
  status: SupplierStatus;
  createdAt: string;
  updatedAt: string;
};

/**
 * A product imported or discovered from an external supplier.
 * This is not the same as a Shopverse catalog product.
 */
export interface SupplierProduct {
  id: SupplierProductId;
  supplierId: SupplierId;
  externalProductId: string;
  externalUrl: string;
  title: string;
  status: SupplierProductStatus;
  lastSyncedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

/**
 * Supplier-specific variant information.
 * Cost and availability belong here because they can differ
 * between variants of the same supplier product.
 */
export interface SupplierProductVariant {
  id: SupplierProductVariantId;
  supplierProductId: SupplierProductId;
  externalVariantId: string;
  title: string;
  sku: string | null;
  costPrice: Money;
  availableQuantity: number | null;
  status: SupplierProductStatus;
  lastSyncedAt: string | null;
}

/**
 * Connects a Shopverse variant to an external supplier variant.
 *
 * One Shopverse variant can have multiple sourcing options.
 */
export interface ProductSupplierSource {
  id: ProductSupplierSourceId;
  productVariantId: EntityId<"product-variant">;
  supplierProductVariantId: SupplierProductVariantId;
  isPreferred: boolean;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}
