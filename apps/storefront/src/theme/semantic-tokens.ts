import { defineSemanticTokens } from "@splenddev/kreativ-ui/core";
import { SemanticTokens } from "@splenddev/kreativ-ui/types";

export const semanticTokens: SemanticTokens = {
  colors: defineSemanticTokens({
    // Backgrounds
    background: {
      light: "{colors.neutral.50}",
      dark: "{colors.neutral.950}",
    },

    surface: {
      light: "{colors.white}",
      dark: "{colors.neutral.900}",
    },

    surfaceMuted: {
      light: "{colors.neutral.100}",
      dark: "{colors.neutral.800}",
    },

    surfaceSubtle: {
      light: "{colors.neutral.50}",
      dark: "{colors.neutral.900}",
    },

    // Brand
    brand: {
      light: "{colors.orange.600}",
      dark: "{colors.orange.400}",
    },

    brandHover: {
      light: "{colors.orange.700}",
      dark: "{colors.orange.300}",
    },

    brandActive: {
      light: "{colors.orange.800}",
      dark: "{colors.orange.200}",
    },

    brandFg: {
      light: "{colors.white}",
      dark: "{colors.neutral.950}",
    },

    // Text
    foreground: {
      light: "{colors.neutral.900}",
      dark: "{colors.neutral.50}",
    },

    text: {
      light: "{colors.neutral.700}",
      dark: "{colors.neutral.300}",
    },

    textMuted: {
      light: "{colors.neutral.600}",
      dark: "{colors.neutral.400}",
    },

    textSubtle: {
      light: "{colors.neutral.500}",
      dark: "{colors.neutral.500}",
    },

    // Borders
    border: {
      light: "{colors.neutral.200}",
      dark: "{colors.neutral.800}",
    },

    borderStrong: {
      light: "{colors.neutral.300}",
      dark: "{colors.neutral.700}",
    },

    borderSubtle: {
      light: "{colors.neutral.100}",
      dark: "{colors.neutral.900}",
    },

    // Interaction
    focusRing: {
      light: "{colors.orange.500}",
      dark: "{colors.orange.400}",
    },

    selection: {
      light: "{colors.orange.100}",
      dark: "{colors.orange.900}",
    },

    // Feedback
    success: {
      light: "{colors.green.600}",
      dark: "{colors.green.600}",
    },

    warning: {
      light: "{colors.amber.600}",
      dark: "{colors.amber.600}",
    },

    error: {
      light: "{colors.red.600}",
      dark: "{colors.red.600}",
    },

    info: {
      light: "{colors.blue.600}",
      dark: "{colors.blue.600}",
    },
  }),
};
