import type { EntityId, FulfillmentId } from "../shared/identifiers.js";

import type { Money } from "../shared/money.js";

export type ShippingRateSource = "supplier" | "platform_fixed" | "dynamic";

export interface ShippingRate {
  id: EntityId<"shipping-rate">;
  name: string;
  source: ShippingRateSource;

  amount: Money;

  estimatedMinDays: number | null;
  estimatedMaxDays: number | null;

  originCountry: string | null;
  destinationCountry: string;
}

export interface ShippingMethod {
  id: EntityId<"shipping-method">;
  name: string;
  description: string | null;
  isActive: boolean;
}

export interface ShippingSelection {
  id: EntityId<"shipping-selection">;

  fulfillmentId: FulfillmentId;
  shippingMethodId: EntityId<"shipping-method">;

  rate: ShippingRate;
  selectedAt: string;
}
