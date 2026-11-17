import type {
  EntityId,
  OrderId,
  PaymentId,
  UserId,
} from "../shared/identifiers.js";

import type { Money } from "../shared/money.js";

export type PaymentProvider = "stripe" | "paystack" | "paypal";

export type PaymentStatus =
  | "pending"
  | "processing"
  | "succeeded"
  | "failed"
  | "cancelled"
  | "partially_refunded"
  | "refunded";

export type PaymentRefundStatus = "pending" | "succeeded" | "failed";

export interface Payment {
  id: PaymentId;

  orderId: OrderId;
  customerId: UserId;

  provider: PaymentProvider;
  providerReference: string | null;

  status: PaymentStatus;

  /** Original payment amount. */
  amount: Money;

  /**
   * Aggregate of successfully processed refunds.
   * Must never exceed amount.
   */
  refundedAmount: Money;

  /**
   * Unique within the relevant payment provider/account.
   * Used to prevent duplicate payment attempts.
   */
  idempotencyKey: string;

  /** Set when the payment is successfully captured. */
  paidAt: string | null;

  createdAt: string;
  updatedAt: string;
}

export interface PaymentRefund {
  id: EntityId<"payment-refund">;

  paymentId: PaymentId;

  /** Refund amount in the payment's original currency. */
  amount: Money;

  reason: string | null;
  providerReference: string | null;

  status: PaymentRefundStatus;

  /** Prevents duplicate refund requests. */
  idempotencyKey: string;

  createdAt: string;
  updatedAt: string;
}
