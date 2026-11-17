import type { AccessAssignmentId, UserId } from "../shared/identifiers.js";

export type AccessStatus = "pending" | "active" | "suspended" | "revoked";

export type PlatformAccessRole = "admin" | "super_admin";

export interface PlatformAccessAssignment {
  id: AccessAssignmentId;
  userId: UserId;
  scope: "platform";
  role: PlatformAccessRole;
  status: AccessStatus;
  assignedAt: string;
  expiresAt: string | null;
}

export type AccessAssignment = PlatformAccessAssignment;
