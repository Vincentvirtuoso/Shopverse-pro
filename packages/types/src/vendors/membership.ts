import type { EntityId, UserId, VendorId } from "../shared/identifiers.js";

export interface VendorMembership {
  id: EntityId<"vendor-membership">;
  vendorId: VendorId;
  userId: UserId;
  role: "owner";
  createdAt: string;
  updatedAt: string;
}
