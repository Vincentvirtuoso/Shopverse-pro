import type { CategoryId, UserId } from "../shared/identifiers.js";

export interface CustomerCategoryPreference {
  userId: UserId;
  categoryId: CategoryId;
  createdAt: string;
}
