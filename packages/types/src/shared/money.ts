/**
 * ISO 4217 currency code.
 *
 * Examples: USD, NGN, JPY, KWD.
 * Runtime validation will be handled by the validation package.
 */
export type CurrencyCode = string;

/**
 * Monetary amount represented in the currency's smallest unit.
 *
 * Examples:
 * - USD 10.50 = 1050
 * - NGN 1500.00 = 150000
 * - JPY 1500 = 1500
 *
 * The amount must be a non-negative or negative safe integer,
 * depending on the operation being represented.
 */
export interface Money {
  amount: number;
  currency: CurrencyCode;
}

/**
 * Exchange rate expressed as:
 * quoteCurrency units per one baseCurrency unit.
 *
 * Example:
 * baseCurrency: USD
 * quoteCurrency: NGN
 * rate: 1500
 *
 * Means 1 USD = 1500 NGN.
 */
export interface ExchangeRate {
  baseCurrency: CurrencyCode;
  quoteCurrency: CurrencyCode;
  rate: number;
  updatedAt: string;
}
