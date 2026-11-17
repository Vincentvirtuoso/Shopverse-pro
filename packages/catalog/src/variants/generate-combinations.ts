import type { ProductOption, ProductOptionValueId } from "@shopverse/types";

export type VariantCombination = ProductOptionValueId[];

export function generateVariantCombinations(
  options: ProductOption[],
): VariantCombination[] {
  if (options.length === 0) {
    return [[]];
  }

  const activeOptions = [...options]
    .filter((option) => option.isActive)
    .sort((a, b) => a.position - b.position);

  if (activeOptions.length === 0) {
    return [[]];
  }

  return activeOptions.reduce<VariantCombination[]>(
    (combinations, option) => {
      const values = option.values
        .filter((value) => value.isActive)
        .sort((a, b) => a.position - b.position);

      if (values.length === 0) {
        return [];
      }

      return combinations.flatMap((combination) =>
        values.map((value) => [...combination, value.id]),
      );
    },
    [[]],
  );
}
