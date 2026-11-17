import { defineToken } from "@splenddev/kreativ-ui/core";

export const tokens = {
  colors: {
    neutral: {
      50: defineToken("#F7F5F1"),
      100: defineToken("#EEEAE3"),
      200: defineToken("#DED9D1"),
      300: defineToken("#C9C2B8"),
      400: defineToken("#A49C92"),
      500: defineToken("#81796F"),
      600: defineToken("#716D66"),
      700: defineToken("#514D47"),
      800: defineToken("#302D29"),
      900: defineToken("#191816"),
      950: defineToken("#100F0E"),
    },

    orange: {
      50: defineToken("#FFF5EF"),
      100: defineToken("#FCE7DC"),
      200: defineToken("#F5CDB9"),
      300: defineToken("#E9A98A"),
      400: defineToken("#D9845D"),
      500: defineToken("#C9653C"),
      600: defineToken("#B84F2B"),
      700: defineToken("#963E21"),
      800: defineToken("#78351F"),
      900: defineToken("#612D1E"),
      950: defineToken("#35160F"),
    },

    white: defineToken("#FFFFFF"),
    black: defineToken("#000000"),

    green: {
      600: defineToken("#24734B"),
    },

    red: {
      600: defineToken("#B42318"),
    },

    amber: {
      600: defineToken("#98651C"),
    },

    blue: {
      600: defineToken("#315F91"),
    },
  },

  fonts: {
    body: defineToken("var(--font-body), sans-serif"),
    heading: defineToken("var(--font-heading), sans-serif"),
    mono: defineToken("var(--font-mono), monospace"),
  },
} as const;
