import type { ProductOption, ProductVariant } from "@shopverse/types";

import type { VariantCombination } from "./generate-combinations.js";
import { getCombinationKey } from "./combination-key.js";
import { findVariantRetirementCandidates } from "./find-retirement-candidates.js";

export interface VariantReconciliation {
  existing: ProductVariant[];
  missing: VariantCombination[];
  retirementCandidates: ProductVariant[];
}

export function reconcileVariantCombinations(
  generated: VariantCombination[],
  existingVariants: ProductVariant[],
  options: ProductOption[],
): VariantReconciliation {
  const existingKeys = new Set(
    existingVariants.map((variant) =>
      getCombinationKey(
        variant.selections.map((selection) => selection.optionValueId),
      ),
    ),
  );

  return {
    existing: existingVariants,
    missing: generated.filter(
      (combination) => !existingKeys.has(getCombinationKey(combination)),
    ),
    retirementCandidates: findVariantRetirementCandidates(
      existingVariants,
      options,
    ),
  };
}
