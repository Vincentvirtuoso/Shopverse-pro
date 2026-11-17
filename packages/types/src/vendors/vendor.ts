import type { UserId, VendorId } from "../shared/identifiers.js";

export type VendorStatus = "active" | "suspended" | "closed";

export interface Vendor {
  id: VendorId;
  name: string;
  slug: string;
  description: string | null;
  logoUrl: string | null;
  status: VendorStatus;
  createdBy: UserId;
  approvedAt: string;
  createdAt: string;
  updatedAt: string;
}
