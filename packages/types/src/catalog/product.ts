import type {
  ProductId,
  ProductVariantId,
  VendorId,
} from "../shared/identifiers.js";

import type { Money, CurrencyCode } from "../shared/money.js";
import type { ProductImage } from "./product-image.js";
import type {
  ProductOption,
  ProductVariantOptionSelection,
} from "./product-option.js";
import type { ProductAttributeValue } from "./product-attribute.js";

export type ProductType = "physical" | "digital";

export type ProductStatus =
  "draft" | "pending_review" | "active" | "rejected" | "archived";

export type ProductOwnership =
  | { ownerType: "platform"; vendorId: null }
  | { ownerType: "vendor"; vendorId: VendorId };

export type ProductVariantStatus =
  "active" | "inactive" | "discontinued" | "archived";

export interface ProductWeight {
  value: number;
  unit: "g" | "kg" | "oz" | "lb";
}

export interface ProductDimensions {
  length: number;
  width: number;
  height: number;
  unit: "mm" | "cm" | "in";
}

export interface ProductShippingDetails {
  weight: ProductWeight | null;
  dimensions: ProductDimensions | null;
}

export interface VariantPurchaseLimits {
  minPerOrder: number;
  maxPerOrder: number | null;
  maxPerCustomer: number | null;
  maxTotalQuantity: number | null;
}

export interface VariantBackorderSettings {
  enabled: boolean;
  maxQuantity: number | null;
}

export interface VariantPreorderSettings {
  enabled: boolean;
  expectedAvailableAt: string | null;
  quantityLimit: number | null;
}

export type BarcodeType = "upc" | "ean" | "gtin";

export interface ProductVariantBarcode {
  type: BarcodeType;
  value: string;
}

export type ProductVariant = {
  id: ProductVariantId;

  /** Generated or manually assigned, globally unique. */
  sku: string;
  skuSource: "generated" | "manual";

  title: string;
  selections: ProductVariantOptionSelection[];

  price: Money;
  compareAtPrice: Money | null;

  barcode: ProductVariantBarcode | null;

  status: ProductVariantStatus;

  /** Null means inherit the product's shipping details. */
  shippingOverrides: {
    weight?: ProductWeight | null;
    dimensions?: ProductDimensions | null;
  } | null;

  purchaseLimits: VariantPurchaseLimits;
  backorder: VariantBackorderSettings;
  preorder: VariantPreorderSettings;

  createdAt: string;
  updatedAt: string;
};

export type Product = ProductOwnership & {
  id: ProductId;

  name: string;
  slug: string;
  description: string;

  type: ProductType;
  status: ProductStatus;

  /** All variants must use this currency for their base prices. */
  baseCurrency: CurrencyCode;

  options: ProductOption[];
  variants: [ProductVariant, ...ProductVariant[]];

  images: ProductImage[];
  attributes: ProductAttributeValue[];

  /** Null for digital products. */
  shipping: ProductShippingDetails | null;

  createdAt: string;
  updatedAt: string;
};
