import type {
  CategoryId,
  ProductCategoryId,
  ProductId,
} from "../shared/identifiers.js";

export interface ProductCategory {
  id: ProductCategoryId;

  productId: ProductId;
  categoryId: CategoryId;

  createdAt: string;
}
