import type { UserId } from "../shared/identifiers.js";

export type UserStatus =
  "active" | "suspended" | "deactivated" | "pending_deletion";

export interface User {
  id: UserId;
  email: string;
  displayName: string | null;
  avatarUrl: string | null;
  emailVerifiedAt: string | null;
  createdAt: string;
  updatedAt: string;
  status: UserStatus;
}
