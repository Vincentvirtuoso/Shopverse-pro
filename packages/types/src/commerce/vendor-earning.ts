import type {
  EntityId,
  OrderId,
  OrderItemId,
  UserId,
  VendorId,
} from "../shared/identifiers.js";
import type { Money } from "../shared/money.js";

export type VendorEarningStatus =
  "pending" | "available" | "reserved" | "paid" | "reversed";

export interface VendorEarning {
  id: EntityId<"vendor-earning">;
  vendorId: VendorId;
  orderId: OrderId;
  orderItemId: OrderItemId;

  grossAmount: Money;
  commissionAmount: Money;
  deductionAmount: Money;
  netAmount: Money;

  status: VendorEarningStatus;

  availableAt: string;
  createdAt: string;
  updatedAt: string;
}
