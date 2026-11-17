import type { VendorApplicationId, UserId } from "../shared/identifiers.js";

export type VendorApplicationStatus =
  "pending" | "approved" | "rejected" | "withdrawn";

export type BusinessVerificationStatus =
  "not_submitted" | "pending" | "verified" | "rejected";

export interface VendorApplication {
  id: VendorApplicationId;
  applicantId: UserId;

  businessName: string;
  businessEmail: string;
  businessPhone: string;
  countryCode: string;
  businessType: string;

  status: VendorApplicationStatus;
  verificationStatus: BusinessVerificationStatus;

  reviewedBy: UserId | null;
  reviewedAt: string | null;
  reviewNotes: string | null;

  createdAt: string;
  updatedAt: string;
}
