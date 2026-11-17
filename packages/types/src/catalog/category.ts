import type { CategoryId } from "../shared/identifiers.js";

export type CategoryStatus = "active" | "inactive";

export interface Category {
  id: CategoryId;

  name: string;
  slug: string;

  description: string | null;
  imageUrl: string | null;

  /** Null means this is a top-level category. */
  parentCategoryId: CategoryId | null;

  status: CategoryStatus;

  position: number;

  seoTitle: string | null;
  seoDescription: string | null;

  createdAt: string;
  updatedAt: string;
}
