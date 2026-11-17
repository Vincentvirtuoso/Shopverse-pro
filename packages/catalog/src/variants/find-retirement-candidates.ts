import type { ProductOption, ProductVariant } from "@shopverse/types";

export function findVariantRetirementCandidates(
  variants: ProductVariant[],
  options: ProductOption[],
): ProductVariant[] {
  const activeOptionIds = new Set(
    options.filter((option) => option.isActive).map((option) => option.id),
  );

  const activeValueIds = new Set(
    options
      .filter((option) => option.isActive)
      .flatMap((option) =>
        option.values
          .filter((value) => value.isActive)
          .map((value) => value.id),
      ),
  );

  return variants.filter((variant) =>
    variant.selections.some(
      (selection) =>
        !activeOptionIds.has(selection.optionId) ||
        !activeValueIds.has(selection.optionValueId),
    ),
  );
}
