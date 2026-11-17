import type { EntityId, ProductId, UserId } from "../shared/identifiers.js";
import type { CurrencyCode } from "../shared/money.js";

export interface CartItem {
  id: EntityId<"cart-item">;
  productId: ProductId;
  variantId: EntityId<"product-variant">;
  quantity: number;
  addedAt: string;
}

export interface Cart {
  id: EntityId<"cart">;
  userId: UserId;
  items: CartItem[];
  currency: CurrencyCode;
  createdAt: string;
  updatedAt: string;
}
