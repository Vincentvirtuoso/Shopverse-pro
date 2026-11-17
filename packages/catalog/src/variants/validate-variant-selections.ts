import type {
  ProductOption,
  ProductVariantOptionSelection,
} from "@shopverse/types";

export interface VariantSelectionValidation {
  valid: boolean;
  errors: string[];
}

export function validateVariantSelections(
  selections: ProductVariantOptionSelection[],
  options: ProductOption[],
): VariantSelectionValidation {
  const errors: string[] = [];
  const selectedOptionIds = new Set<string>();

  const activeOptions = options.filter((option) => option.isActive);

  const activeOptionMap = new Map(
    activeOptions.map((option) => [option.id, option]),
  );

  for (const selection of selections) {
    if (selectedOptionIds.has(selection.optionId)) {
      errors.push("An option cannot be selected more than once.");
      continue;
    }

    selectedOptionIds.add(selection.optionId);

    const option = activeOptionMap.get(selection.optionId);

    if (!option) {
      errors.push("The selected option does not exist or is inactive.");
      continue;
    }

    const value = option.values.find(
      (item) => item.id === selection.optionValueId,
    );

    if (!value || !value.isActive) {
      errors.push(
        "The selected value does not belong to the option or is inactive.",
      );
    }
  }

  for (const option of activeOptions) {
    if (!selectedOptionIds.has(option.id)) {
      errors.push(`A selection is required for "${option.name}".`);
    }
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}
