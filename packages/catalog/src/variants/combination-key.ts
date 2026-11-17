import type { ProductOptionValueId } from "@shopverse/types";

export function getCombinationKey(valueIds: ProductOptionValueId[]): string {
  return [...valueIds].sort().join(":");
}
