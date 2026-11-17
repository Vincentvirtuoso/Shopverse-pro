import type {
  CatalogAttributeId,
  ProductAttributeValueId,
  ProductVariantId,
} from "../shared/identifiers.js";

interface ProductAttributeValueBase {
  id: ProductAttributeValueId;
  attributeId: CatalogAttributeId | null;
  name: string;
  value: string | number | boolean;
}

export type ProductAttributeValue =
  | (ProductAttributeValueBase & {
      scope: "product";
      variantId: null;
    })
  | (ProductAttributeValueBase & {
      scope: "variant";
      variantId: ProductVariantId;
    });
