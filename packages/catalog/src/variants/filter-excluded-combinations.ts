import type {
  ExcludedVariantCombination,
} from "@shopverse/types";

import type { VariantCombination } from "./generate-combinations.js";
import { getCombinationKey } from "./combination-key.js";

export function filterExcludedCombinations(
  combinations: VariantCombination[],
  excluded: ExcludedVariantCombination[],
): VariantCombination[] {
  const excludedKeys = new Set(
    excluded.map((item) => getCombinationKey(item.optionValueIds)),
  );

  return combinations.filter(
    (combination) => !excludedKeys.has(getCombinationKey(combination)),
  );
}
