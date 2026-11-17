import type {
  EntityId,
  OrderId,
  ProductId,
  UserId,
} from "../shared/identifiers.js";

export type ReviewStatus = "pending" | "published" | "rejected" | "hidden";

export interface Review {
  id: EntityId<"review">;

  productId: ProductId;
  customerId: UserId;
  orderId: OrderId | null;

  rating: number;
  title: string | null;
  comment: string | null;
  images: string[];

  status: ReviewStatus;

  createdAt: string;
  updatedAt: string;
}
