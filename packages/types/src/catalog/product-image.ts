import type {
  ProductId,
  ProductImageId,
  ProductVariantId,
} from "../shared/identifiers.js";

export interface ProductImage {
  id: ProductImageId;
  productId: ProductId;

  /**
   * Null means this image belongs to the general product gallery.
   * Otherwise, it is associated with a specific variant.
   */
  variantId: ProductVariantId | null;

  url: string;
  alt: string | null;

  /** Position in the product image gallery. */
  position: number;

  /** Only one general gallery image should be primary per product. */
  isPrimary: boolean;

  createdAt: string;
  updatedAt: string;
}
