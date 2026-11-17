import type {
  CatalogAttributeId,
  ProductId,
  ProductOptionId,
  ProductOptionValueId,
  ProductVariantId,
} from "../shared/identifiers.js";

export interface CatalogAttributeDefinition {
  id: CatalogAttributeId;
  name: string;
  slug: string;
  dataType: "text" | "number" | "boolean";
  usage: "variant_option" | "descriptive" | "both";
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface ProductOptionValue {
  id: ProductOptionValueId;
  optionId: ProductOptionId;
  value: string;
  position: number;
  isActive: boolean;
}

export interface ProductOption {
  id: ProductOptionId;
  productId: ProductId;
  attributeId: CatalogAttributeId | null;
  name: string;
  position: number;
  values: ProductOptionValue[];
  isActive: boolean;
}

export interface ProductVariantOptionSelection {
  optionId: ProductOptionId;
  optionValueId: ProductOptionValueId;
}

/**
 * Stores combinations deliberately excluded by the vendor.
 * This prevents them from reappearing during future generation.
 */
export interface ExcludedVariantCombination {
  id: string;
  productId: ProductId;
  optionValueIds: ProductOptionValueId[];
  createdAt: string;
}
