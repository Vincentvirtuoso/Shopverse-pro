import type { ProductVariant } from "@shopverse/types";

import { getCombinationKey } from "./combination-key.js";

export function findDuplicateVariantCombinations(
  variants: ProductVariant[],
): ProductVariant[][] {
  const groups = new Map<string, ProductVariant[]>();

  for (const variant of variants) {
    const key = getCombinationKey(
      variant.selections.map((selection) => selection.optionValueId),
    );

    const group = groups.get(key) ?? [];
    group.push(variant);
    groups.set(key, group);
  }

  return [...groups.values()].filter((group) => group.length > 1);
}
