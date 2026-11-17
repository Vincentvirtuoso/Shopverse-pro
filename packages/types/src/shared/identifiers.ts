/**
 * Branded identifiers prevent accidentally mixing IDs
 * belonging to different domain entities.
 */
export type EntityId<T extends string = string> = string & {
  readonly __entityId: T;
};

export type UserId = EntityId<"user">;
export type VendorId = EntityId<"vendor">;
export type ProductId = EntityId<"product">;
export type SupplierId = EntityId<"supplier">;
export type OrderId = EntityId<"order">;
export type PaymentId = EntityId<"payment">;
export type ShipmentId = EntityId<"shipment">;
export type SupplierProductId = EntityId<"supplier-product">;
export type SupplierProductVariantId = EntityId<"supplier-product-variant">;
export type ProductSupplierSourceId = EntityId<"product-supplier-source">;
export type OrderItemId = EntityId<"order-item">;
export type FulfillmentId = EntityId<"fulfillment">;
export type FulfillmentItemId = EntityId<"fulfillment-item">;
export type InventoryLocationId = EntityId<"inventory-location">;
export type DigitalAssetId = EntityId<"digital-asset">;
export type DigitalPurchaseAccessId = EntityId<"digital-purchase-access">;
export type PaymentRefundId = EntityId<"payment-refund">;
export type ProductVariantId = EntityId<"product-variant">;
export type ProductImageId = EntityId<"product-image">;
export type CategoryId = EntityId<"category">;
export type ProductCategoryId = EntityId<"product-category">;
export type ProductDiscountId = EntityId<"product-discount">;
export type ReturnId = EntityId<"return">;
export type ReturnItemId = EntityId<"return-item">;



export type CatalogAttributeId = EntityId<"catalog-attribute">;
export type ProductOptionId = EntityId<"product-option">;
export type ProductOptionValueId = EntityId<"product-option-value">;
export type ProductAttributeValueId = EntityId<"product-attribute-value">;

export type InventoryReservationId = EntityId<"inventory-reservation">;
export type InventoryReservationItemId = EntityId<"inventory-reservation-item">;
export type CheckoutId = EntityId<"checkout">;

export type AccessAssignmentId = EntityId<"access-assignment">;
export type VendorApplicationId = EntityId<"vendor-application">;