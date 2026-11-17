import { defineTypography } from "@splenddev/kreativ-ui/core";

export const typography = defineTypography({
  body: {
    fontFamily: "{fonts.body}",
    fontSize: "14px",
    lineHeight: "1.6",
  },

  bodySmall: {
    fontFamily: "{fonts.body}",
    fontSize: "12px",
    lineHeight: "1.6",
  },

  heading: {
    fontFamily: "{fonts.heading}",
    fontWeight: 600,
    letterSpacing: "-0.035em",
  },

  display: {
    fontFamily: "{fonts.heading}",
    fontWeight: 400,
    letterSpacing: "-0.045em",
  },

  label: {
    fontFamily: "{fonts.body}",
    fontSize: "12px",
    fontWeight: 500,
    letterSpacing: "0.02em",
  },

  mono: {
    fontFamily: "{fonts.mono}",
    fontSize: "12px",
    lineHeight: "1.5",
  },
});
