import type { EntityId, UserId } from "../shared/identifiers.js";

export interface Address {
  id: EntityId<"address">;
  userId: UserId;

  firstName: string;
  lastName: string;
  company: string | null;

  addressLine1: string;
  addressLine2: string | null;
  city: string;
  state: string | null;
  postalCode: string | null;
  countryCode: string;

  phone: string | null;
  isDefaultShipping: boolean;
  isDefaultBilling: boolean;

  createdAt: string;
  updatedAt: string;
}
