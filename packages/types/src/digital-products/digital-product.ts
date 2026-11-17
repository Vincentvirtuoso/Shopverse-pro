import type {
  DigitalAssetId,
  DigitalPurchaseAccessId,
  EntityId,
  OrderId,
  OrderItemId,
  ProductId,
  UserId,
} from "../shared/identifiers.js";

export type DigitalAssetType =
  "pdf" | "ebook" | "image" | "audio" | "video" | "archive" | "other";

export interface DigitalAsset {
  id: DigitalAssetId;
  productId: ProductId;

  name: string;
  fileType: DigitalAssetType;

  /**
   * Private storage path, never a public download URL.
   */
  storagePath: string;

  fileSize: number;

  downloadLimit: number | null;
  isActive: boolean;

  createdAt: string;
}

export interface DigitalPurchaseAccess {
  id: DigitalPurchaseAccessId;

  orderId: OrderId;
  orderItemId: OrderItemId;
  customerId: UserId;
  assetId: DigitalAssetId;

  downloadCount: number;
  downloadLimit: number | null;

  expiresAt: string | null;

  createdAt: string;
}
