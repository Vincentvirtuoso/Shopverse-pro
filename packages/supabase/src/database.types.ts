Scope: all 9 workspace projects
? Verifying lockfile against supply-chain policies (610 entries)...
Lockfile is up to date, resolution step is skipped
Packages: -1
-
Γ£ô Lockfile passes supply-chain policies (610 entries in 16.2s)

Done in 18.4s using pnpm v11.25.0
export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.18"
  }
  public: {
    Tables: {
      audit_logs: {
        Row: {
          action: string
          actor_id: string
          created_at: string
          id: string
          metadata: Json
          target_id: string
          target_type: string
        }
        Insert: {
          action: string
          actor_id: string
          created_at?: string
          id?: string
          metadata?: Json
          target_id: string
          target_type: string
        }
        Update: {
          action?: string
          actor_id?: string
          created_at?: string
          id?: string
          metadata?: Json
          target_id?: string
          target_type?: string
        }
        Relationships: [
          {
            foreignKeyName: "audit_logs_actor_id_fkey"
            columns: ["actor_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      catalog_attributes: {
        Row: {
          created_at: string
          data_type: Database["public"]["Enums"]["catalog_attribute_data_type"]
          id: string
          is_active: boolean
          name: string
          slug: string
          updated_at: string
          usage: Database["public"]["Enums"]["catalog_attribute_usage"]
        }
        Insert: {
          created_at?: string
          data_type: Database["public"]["Enums"]["catalog_attribute_data_type"]
          id?: string
          is_active?: boolean
          name: string
          slug: string
          updated_at?: string
          usage: Database["public"]["Enums"]["catalog_attribute_usage"]
        }
        Update: {
          created_at?: string
          data_type?: Database["public"]["Enums"]["catalog_attribute_data_type"]
          id?: string
          is_active?: boolean
          name?: string
          slug?: string
          updated_at?: string
          usage?: Database["public"]["Enums"]["catalog_attribute_usage"]
        }
        Relationships: []
      }
      categories: {
        Row: {
          created_at: string
          description: string | null
          id: string
          image_url: string | null
          name: string
          parent_category_id: string | null
          position: number
          seo_description: string | null
          seo_title: string | null
          slug: string
          status: Database["public"]["Enums"]["category_status"]
          updated_at: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          image_url?: string | null
          name: string
          parent_category_id?: string | null
          position?: number
          seo_description?: string | null
          seo_title?: string | null
          slug: string
          status?: Database["public"]["Enums"]["category_status"]
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          image_url?: string | null
          name?: string
          parent_category_id?: string | null
          position?: number
          seo_description?: string | null
          seo_title?: string | null
          slug?: string
          status?: Database["public"]["Enums"]["category_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "categories_parent_category_id_fkey"
            columns: ["parent_category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
        ]
      }
      category_commission_overrides: {
        Row: {
          category_id: string
          created_at: string
          effective_from: string
          effective_until: string | null
          id: string
          is_active: boolean
          priority: number
          rate_basis_points: number
          updated_at: string
        }
        Insert: {
          category_id: string
          created_at?: string
          effective_from?: string
          effective_until?: string | null
          id?: string
          is_active?: boolean
          priority?: number
          rate_basis_points: number
          updated_at?: string
        }
        Update: {
          category_id?: string
          created_at?: string
          effective_from?: string
          effective_until?: string | null
          id?: string
          is_active?: boolean
          priority?: number
          rate_basis_points?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "category_commission_overrides_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
        ]
      }
      checkout_items: {
        Row: {
          checkout_id: string
          created_at: string
          discount_amount: number
          id: string
          product_id: string
          quantity: number
          snapshot: Json
          subtotal_amount: number
          unit_price_amount: number
          updated_at: string
          variant_id: string
          vendor_id: string | null
        }
        Insert: {
          checkout_id: string
          created_at?: string
          discount_amount?: number
          id?: string
          product_id: string
          quantity: number
          snapshot: Json
          subtotal_amount: number
          unit_price_amount: number
          updated_at?: string
          variant_id: string
          vendor_id?: string | null
        }
        Update: {
          checkout_id?: string
          created_at?: string
          discount_amount?: number
          id?: string
          product_id?: string
          quantity?: number
          snapshot?: Json
          subtotal_amount?: number
          unit_price_amount?: number
          updated_at?: string
          variant_id?: string
          vendor_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "checkout_item_variant_belongs_to_product"
            columns: ["variant_id", "product_id"]
            isOneToOne: false
            referencedRelation: "product_variants"
            referencedColumns: ["id", "product_id"]
          },
          {
            foreignKeyName: "checkout_items_checkout_id_fkey"
            columns: ["checkout_id"]
            isOneToOne: false
            referencedRelation: "checkouts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checkout_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checkout_items_vendor_id_fkey"
            columns: ["vendor_id"]
            isOneToOne: false
            referencedRelation: "vendors"
            referencedColumns: ["id"]
          },
        ]
      }
      checkouts: {
        Row: {
          billing_address_snapshot: Json | null
          completed_at: string | null
          created_at: string
          currency: string
          discount_total_amount: number
          expires_at: string
          grand_total_amount: number
          id: string
          order_id: string | null
          shipping_address_snapshot: Json | null
          shipping_total_amount: number
          status: Database["public"]["Enums"]["checkout_status"]
          subtotal_amount: number
          tax_total_amount: number
          updated_at: string
          user_id: string
        }
        Insert: {
          billing_address_snapshot?: Json | null
          completed_at?: string | null
          created_at?: string
          currency: string
          discount_total_amount?: number
          expires_at: string
          grand_total_amount?: number
          id?: string
          order_id?: string | null
          shipping_address_snapshot?: Json | null
          shipping_total_amount?: number
          status?: Database["public"]["Enums"]["checkout_status"]
          subtotal_amount?: number
          tax_total_amount?: number
          updated_at?: string
          user_id: string
        }
        Update: {
          billing_address_snapshot?: Json | null
          completed_at?: string | null
          created_at?: string
          currency?: string
          discount_total_amount?: number
          expires_at?: string
          grand_total_amount?: number
          id?: string
          order_id?: string | null
          shipping_address_snapshot?: Json | null
          shipping_total_amount?: number
          status?: Database["public"]["Enums"]["checkout_status"]
          subtotal_amount?: number
          tax_total_amount?: number
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "checkouts_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: true
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checkouts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      commission_policies: {
        Row: {
          created_at: string
          default_rate_basis_points: number
          effective_from: string
          effective_until: string | null
          id: string
          is_active: boolean
          logistics_rate_basis_points: number
          name: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          default_rate_basis_points: number
          effective_from?: string
          effective_until?: string | null
          id?: string
          is_active?: boolean
          logistics_rate_basis_points?: number
          name: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          default_rate_basis_points?: number
          effective_from?: string
          effective_until?: string | null
          id?: string
          is_active?: boolean
          logistics_rate_basis_points?: number
          name?: string
          updated_at?: string
        }
        Relationships: []
      }
      customer_addresses: {
        Row: {
          address_line_1: string
          address_line_2: string | null
          city: string
          company: string | null
          country_code: string
          created_at: string
          first_name: string
          id: string
          is_default_billing: boolean
          is_default_shipping: boolean
          last_name: string
          phone: string | null
          postal_code: string | null
          state: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          address_line_1: string
          address_line_2?: string | null
          city: string
          company?: string | null
          country_code: string
          created_at?: string
          first_name: string
          id?: string
          is_default_billing?: boolean
          is_default_shipping?: boolean
          last_name: string
          phone?: string | null
          postal_code?: string | null
          state?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          address_line_1?: string
          address_line_2?: string | null
          city?: string
          company?: string | null
          country_code?: string
          created_at?: string
          first_name?: string
          id?: string
          is_default_billing?: boolean
          is_default_shipping?: boolean
          last_name?: string
          phone?: string | null
          postal_code?: string | null
          state?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "customer_addresses_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      customer_category_preferences: {
        Row: {
          category_id: string
          created_at: string
          user_id: string
        }
        Insert: {
          category_id: string
          created_at?: string
          user_id: string
        }
        Update: {
          category_id?: string
          created_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "customer_category_preferences_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "customer_category_preferences_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      customer_profiles: {
        Row: {
          created_at: string
          marketing_emails_enabled: boolean
          onboarding_completed_at: string | null
          phone: string | null
          phone_verified_at: string | null
          preferred_currency: string
          preferred_locale: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          marketing_emails_enabled?: boolean
          onboarding_completed_at?: string | null
          phone?: string | null
          phone_verified_at?: string | null
          preferred_currency?: string
          preferred_locale?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          marketing_emails_enabled?: boolean
          onboarding_completed_at?: string | null
          phone?: string | null
          phone_verified_at?: string | null
          preferred_currency?: string
          preferred_locale?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "customer_profiles_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      digital_assets: {
        Row: {
          created_at: string
          download_limit: number | null
          file_size: number
          file_type: Database["public"]["Enums"]["digital_asset_type"]
          id: string
          is_active: boolean
          name: string
          product_id: string
          storage_path: string
        }
        Insert: {
          created_at?: string
          download_limit?: number | null
          file_size: number
          file_type: Database["public"]["Enums"]["digital_asset_type"]
          id?: string
          is_active?: boolean
          name: string
          product_id: string
          storage_path: string
        }
        Update: {
          created_at?: string
          download_limit?: number | null
          file_size?: number
          file_type?: Database["public"]["Enums"]["digital_asset_type"]
          id?: string
          is_active?: boolean
          name?: string
          product_id?: string
          storage_path?: string
        }
        Relationships: [
          {
            foreignKeyName: "digital_assets_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      digital_purchase_access: {
        Row: {
          asset_id: string
          created_at: string
          customer_id: string
          download_count: number
          download_limit: number | null
          expires_at: string | null
          id: string
          order_id: string
          order_item_id: string
          revocation_reason: string | null
          revoked_at: string | null
        }
        Insert: {
          asset_id: string
          created_at?: string
          customer_id: string
          download_count?: number
          download_limit?: number | null
          expires_at?: string | null
          id?: string
          order_id: string
          order_item_id: string
          revocation_reason?: string | null
          revoked_at?: string | null
        }
        Update: {
          asset_id?: string
          created_at?: string
          customer_id?: string
          download_count?: number
          download_limit?: number | null
          expires_at?: string | null
          id?: string
          order_id?: string
          order_item_id?: string
          revocation_reason?: string | null
          revoked_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "digital_purchase_access_asset_id_fkey"
            columns: ["asset_id"]
            isOneToOne: false
            referencedRelation: "digital_assets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "digital_purchase_access_customer_id_fkey"
            columns: ["customer_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "digital_purchase_access_order_item_fk"
            columns: ["order_item_id", "order_id"]
            isOneToOne: false
            referencedRelation: "order_items"
            referencedColumns: ["id", "order_id"]
          },
        ]
      }
      excluded_variant_combinations: {
        Row: {
          created_at: string
          id: string
          option_value_ids: string[]
          product_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          option_value_ids: string[]
          product_id: string
        }
        Update: {
          created_at?: string
          id?: string
          option_value_ids?: string[]
          product_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "excluded_variant_combinations_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      fulfillment_items: {
        Row: {
          created_at: string
          fulfillment_id: string
          id: string
          order_id: string
          order_item_id: string
          quantity: number
        }
        Insert: {
          created_at?: string
          fulfillment_id: string
          id?: string
          order_id: string
          order_item_id: string
          quantity: number
        }
        Update: {
          created_at?: string
          fulfillment_id?: string
          id?: string
          order_id?: string
          order_item_id?: string
          quantity?: number
        }
        Relationships: [
          {
            foreignKeyName: "fulfillment_item_fulfillment_order_fkey"
            columns: ["fulfillment_id", "order_id"]
            isOneToOne: false
            referencedRelation: "fulfillments"
            referencedColumns: ["id", "order_id"]
          },
          {
            foreignKeyName: "fulfillment_item_order_item_fkey"
            columns: ["order_item_id", "order_id"]
            isOneToOne: false
            referencedRelation: "order_items"
            referencedColumns: ["id", "order_id"]
          },
        ]
      }
      fulfillments: {
        Row: {
          created_at: string
          external_order_reference: string | null
          id: string
          order_id: string
          source_type: Database["public"]["Enums"]["fulfillment_source_type"]
          status: Database["public"]["Enums"]["fulfillment_status"]
          supplier_id: string | null
          updated_at: string
          vendor_id: string | null
        }
        Insert: {
          created_at?: string
          external_order_reference?: string | null
          id?: string
          order_id: string
          source_type: Database["public"]["Enums"]["fulfillment_source_type"]
          status?: Database["public"]["Enums"]["fulfillment_status"]
          supplier_id?: string | null
          updated_at?: string
          vendor_id?: string | null
        }
        Update: {
          created_at?: string
          external_order_reference?: string | null
          id?: string
          order_id?: string
          source_type?: Database["public"]["Enums"]["fulfillment_source_type"]
          status?: Database["public"]["Enums"]["fulfillment_status"]
          supplier_id?: string | null
          updated_at?: string
          vendor_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fulfillments_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fulfillments_vendor_id_fkey"
            columns: ["vendor_id"]
            isOneToOne: false
            referencedRelation: "vendors"
            referencedColumns: ["id"]
          },
        ]
      }
      inventory_adjustments: {
        Row: {
          created_at: string
          id: string
          inventory_level_id: string
          note: string | null
          quantity_change: number
          reason: Database["public"]["Enums"]["inventory_adjustment_reason"]
          reference_id: string | null
        }
        Insert: {
          created_at?: string
          id?: string
          inventory_level_id: string
          note?: string | null
          quantity_change: number
          reason: Database["public"]["Enums"]["inventory_adjustment_reason"]
          reference_id?: string | null
        }
        Update: {
          created_at?: string
          id?: string
          inventory_level_id?: string
          note?: string | null
          quantity_change?: number
          reason?: Database["public"]["Enums"]["inventory_adjustment_reason"]
          reference_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "inventory_adjustments_inventory_level_id_fkey"
            columns: ["inventory_level_id"]
            isOneToOne: false
            referencedRelation: "inventory_levels"
            referencedColumns: ["id"]
          },
        ]
      }
      inventory_levels: {
        Row: {
          id: string
          location_id: string
          on_hand_quantity: number
          reserved_quantity: number
          tracking_mode: Database["public"]["Enums"]["inventory_tracking_mode"]
          updated_at: string
          variant_id: string
        }
        Insert: {
          id?: string
          location_id: string
          on_hand_quantity?: number
          reserved_quantity?: number
          tracking_mode?: Database["public"]["Enums"]["inventory_tracking_mode"]
          updated_at?: string
          variant_id: string
        }
        Update: {
          id?: string
          location_id?: string
          on_hand_quantity?: number
          reserved_quantity?: number
          tracking_mode?: Database["public"]["Enums"]["inventory_tracking_mode"]
          updated_at?: string
          variant_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "inventory_levels_location_id_fkey"
            columns: ["location_id"]
            isOneToOne: false
            referencedRelation: "inventory_locations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "inventory_levels_variant_id_fkey"
            columns: ["variant_id"]
            isOneToOne: false
            referencedRelation: "product_variants"
            referencedColumns: ["id"]
          },
        ]
      }
      inventory_locations: {
        Row: {
          code: string
          created_at: string
          id: string
          is_active: boolean
          name: string
          owner_type: Database["public"]["Enums"]["inventory_location_ownership_type"]
          type: Database["public"]["Enums"]["inventory_location_type"]
          updated_at: string
          vendor_id: string | null
        }
        Insert: {
          code: string
          created_at?: string
          id?: string
          is_active?: boolean
          name: string
          owner_type: Database["public"]["Enums"]["inventory_location_ownership_type"]
          type: Database["public"]["Enums"]["inventory_location_type"]
          updated_at?: string
          vendor_id?: string | null
        }
        Update: {
          code?: string
          created_at?: string
          id?: string
          is_active?: boolean
          name?: string
          owner_type?: Database["public"]["Enums"]["inventory_location_ownership_type"]
          type?: Database["public"]["Enums"]["inventory_location_type"]
          updated_at?: string
          vendor_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "inventory_locations_vendor_id_fkey"
            columns: ["vendor_id"]
            isOneToOne: false
            referencedRelation: "vendors"
            referencedColumns: ["id"]
          },
        ]
      }
      inventory_reservation_items: {
        Row: {
          created_at: string
          id: string
          inventory_level_id: string
          quantity: number
          reservation_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          inventory_level_id: string
          quantity: number
          reservation_id: string
        }
        Update: {
          created_at?: string
          id?: string
          inventory_level_id?: string
          quantity?: number
          reservation_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "inventory_reservation_items_inventory_level_id_fkey"
            columns: ["inventory_level_id"]
            isOneToOne: false
            referencedRelation: "inventory_levels"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "inventory_reservation_items_reservation_id_fkey"
            columns: ["reservation_id"]
            isOneToOne: false
            referencedRelation: "inventory_reservations"
            referencedColumns: ["id"]
          },
        ]
      }
      inventory_reservations: {
        Row: {
          checkout_id: string
          created_at: string
          expires_at: string
          id: string
          status: Database["public"]["Enums"]["inventory_reservation_status"]
          updated_at: string
        }
        Insert: {
          checkout_id: string
          created_at?: string
          expires_at: string
          id?: string
          status?: Database["public"]["Enums"]["inventory_reservation_status"]
          updated_at?: string
        }
        Update: {
          checkout_id?: string
          created_at?: string
          expires_at?: string
          id?: string
          status?: Database["public"]["Enums"]["inventory_reservation_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "inventory_reservations_checkout_id_fkey"
            columns: ["checkout_id"]
            isOneToOne: true
            referencedRelation: "checkouts"
            referencedColumns: ["id"]
          },
        ]
      }
      order_item_commissions: {
        Row: {
          category_override_id: string | null
          commissionable_amount: number
          created_at: string
          currency: string
          id: string
          logistics_applied: boolean
          logistics_commission_amount: number
          logistics_rate_basis_points: number
          order_item_id: string
          policy_id: string | null
          standard_commission_amount: number
          standard_rate_basis_points: number
          standard_rate_source: string
          total_commission_amount: number
          vendor_net_amount: number
          vendor_override_id: string | null
        }
        Insert: {
          category_override_id?: string | null
          commissionable_amount: number
          created_at?: string
          currency: string
          id?: string
          logistics_applied?: boolean
          logistics_commission_amount?: number
          logistics_rate_basis_points?: number
          order_item_id: string
          policy_id?: string | null
          standard_commission_amount: number
          standard_rate_basis_points: number
          standard_rate_source: string
          total_commission_amount: number
          vendor_net_amount: number
          vendor_override_id?: string | null
        }
        Update: {
          category_override_id?: string | null
          commissionable_amount?: number
          created_at?: string
          currency?: string
          id?: string
          logistics_applied?: boolean
          logistics_commission_amount?: number
          logistics_rate_basis_points?: number
          order_item_id?: string
          policy_id?: string | null
          standard_commission_amount?: number
          standard_rate_basis_points?: number
          standard_rate_source?: string
          total_commission_amount?: number
          vendor_net_amount?: number
          vendor_override_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "order_item_commissions_category_override_id_fkey"
            columns: ["category_override_id"]
            isOneToOne: false
            referencedRelation: "category_commission_overrides"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_item_commissions_order_item_id_fkey"
            columns: ["order_item_id"]
            isOneToOne: true
            referencedRelation: "order_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_item_commissions_policy_id_fkey"
            columns: ["policy_id"]
            isOneToOne: false
            referencedRelation: "commission_policies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_item_commissions_vendor_override_id_fkey"
            columns: ["vendor_override_id"]
            isOneToOne: false
            referencedRelation: "vendor_commission_overrides"
            referencedColumns: ["id"]
          },
        ]
      }
      order_items: {
        Row: {
          created_at: string
          id: string
          order_id: string
          product_id: string
          quantity: number
          snapshot: Json
          subtotal_amount: number
          unit_price_amount: number
          variant_id: string
          vendor_id: string | null
        }
        Insert: {
          created_at?: string
          id?: string
          order_id: string
          product_id: string
          quantity: number
          snapshot: Json
          subtotal_amount: number
          unit_price_amount: number
          variant_id: string
          vendor_id?: string | null
        }
        Update: {
          created_at?: string
          id?: string
          order_id?: string
          product_id?: string
          quantity?: number
          snapshot?: Json
          subtotal_amount?: number
          unit_price_amount?: number
          variant_id?: string
          vendor_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "order_item_variant_belongs_to_product"
            columns: ["variant_id", "product_id"]
            isOneToOne: false
            referencedRelation: "product_variants"
            referencedColumns: ["id", "product_id"]
          },
          {
            foreignKeyName: "order_items_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_items_vendor_id_fkey"
            columns: ["vendor_id"]
            isOneToOne: false
            referencedRelation: "vendors"
            referencedColumns: ["id"]
          },
        ]
      }
      order_return_eligibility_snapshots: {
        Row: {
          order_id: string
          policy_id: string
          return_eligibility_days: number
          snapshotted_at: string
        }
        Insert: {
          order_id: string
          policy_id: string
          return_eligibility_days: number
          snapshotted_at?: string
        }
        Update: {
          order_id?: string
          policy_id?: string
          return_eligibility_days?: number
          snapshotted_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "order_return_eligibility_snapshots_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: true
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_return_eligibility_snapshots_policy_id_fkey"
            columns: ["policy_id"]
            isOneToOne: false
            referencedRelation: "return_eligibility_policies"
            referencedColumns: ["id"]
          },
        ]
      }
      orders: {
        Row: {
          billing_address_snapshot: Json | null
          created_at: string
          currency: string
          customer_id: string
          discount_total_amount: number
          grand_total_amount: number
          id: string
          order_number: string
          paid_at: string | null
          placed_at: string | null
          shipping_address_snapshot: Json | null
          shipping_total_amount: number
          status: Database["public"]["Enums"]["order_status"]
          subtotal_amount: number
          tax_total_amount: number
          updated_at: string
        }
        Insert: {
          billing_address_snapshot?: Json | null
          created_at?: string
          currency: string
          customer_id: string
          discount_total_amount?: number
          grand_total_amount: number
          id?: string
          order_number: string
          paid_at?: string | null
          placed_at?: string | null
          shipping_address_snapshot?: Json | null
          shipping_total_amount?: number
          status?: Database["public"]["Enums"]["order_status"]
          subtotal_amount: number
          tax_total_amount?: number
          updated_at?: string
        }
        Update: {
          billing_address_snapshot?: Json | null
          created_at?: string
          currency?: string
          customer_id?: string
          discount_total_amount?: number
          grand_total_amount?: number
          id?: string
          order_number?: string
          paid_at?: string | null
          placed_at?: string | null
          shipping_address_snapshot?: Json | null
          shipping_total_amount?: number
          status?: Database["public"]["Enums"]["order_status"]
          subtotal_amount?: number
          tax_total_amount?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "orders_customer_id_fkey"
            columns: ["customer_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      payment_refunds: {
        Row: {
          amount: number
          created_at: string
          currency: string
          id: string
          idempotency_key: string
          payment_id: string
          provider_reference: string | null
          reason: string | null
          status: Database["public"]["Enums"]["payment_refund_status"]
          updated_at: string
        }
        Insert: {
          amount: number
          created_at?: string
          currency: string
          id?: string
          idempotency_key: string
          payment_id: string
          provider_reference?: string | null
          reason?: string | null
          status?: Database["public"]["Enums"]["payment_refund_status"]
          updated_at?: string
        }
        Update: {
          amount?: number
          created_at?: string
          currency?: string
          id?: string
          idempotency_key?: string
          payment_id?: string
          provider_reference?: string | null
          reason?: string | null
          status?: Database["public"]["Enums"]["payment_refund_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "payment_refunds_payment_id_fkey"
            columns: ["payment_id"]
            isOneToOne: false
            referencedRelation: "payments"
            referencedColumns: ["id"]
          },
        ]
      }
      payments: {
        Row: {
          amount: number
          created_at: string
          currency: string
          customer_id: string
          id: string
          idempotency_key: string
          order_id: string
          paid_at: string | null
          provider: Database["public"]["Enums"]["payment_provider"]
          provider_reference: string | null
          refunded_amount: number
          status: Database["public"]["Enums"]["payment_status"]
          updated_at: string
        }
        Insert: {
          amount: number
          created_at?: string
          currency: string
          customer_id: string
          id?: string
          idempotency_key: string
          order_id: string
          paid_at?: string | null
          provider: Database["public"]["Enums"]["payment_provider"]
          provider_reference?: string | null
          refunded_amount?: number
          status?: Database["public"]["Enums"]["payment_status"]
          updated_at?: string
        }
        Update: {
          amount?: number
          created_at?: string
          currency?: string
          customer_id?: string
          id?: string
          idempotency_key?: string
          order_id?: string
          paid_at?: string | null
          provider?: Database["public"]["Enums"]["payment_provider"]
          provider_reference?: string | null
          refunded_amount?: number
          status?: Database["public"]["Enums"]["payment_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "payment_order_customer_fkey"
            columns: ["order_id", "customer_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id", "customer_id"]
          },
        ]
      }
      platform_access_assignments: {
        Row: {
          assigned_at: string
          assigned_by: string | null
          expires_at: string | null
          id: string
          role: Database["public"]["Enums"]["platform_access_role"]
          status: Database["public"]["Enums"]["access_status"]
          user_id: string
        }
        Insert: {
          assigned_at?: string
          assigned_by?: string | null
          expires_at?: string | null
          id?: string
          role: Database["public"]["Enums"]["platform_access_role"]
          status?: Database["public"]["Enums"]["access_status"]
          user_id: string
        }
        Update: {
          assigned_at?: string
          assigned_by?: string | null
          expires_at?: string | null
          id?: string
          role?: Database["public"]["Enums"]["platform_access_role"]
          status?: Database["public"]["Enums"]["access_status"]
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "platform_access_assignments_assigned_by_fkey"
            columns: ["assigned_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "platform_access_assignments_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      platform_permissions: {
        Row: {
          description: string
          key: string
        }
        Insert: {
          description: string
          key: string
        }
        Update: {
          description?: string
          key?: string
        }
        Relationships: []
      }
      product_attribute_values: {
        Row: {
          attribute_id: string | null
          created_at: string
          id: string
          name: string
          product_id: string
          scope: Database["public"]["Enums"]["product_attribute_scope"]
          updated_at: string
          value_boolean: boolean | null
          value_number: number | null
          value_text: string | null
          value_type: Database["public"]["Enums"]["catalog_attribute_data_type"]
          variant_id: string | null
        }
        Insert: {
          attribute_id?: string | null
          created_at?: string
          id?: string
          name: string
          product_id: string
          scope: Database["public"]["Enums"]["product_attribute_scope"]
          updated_at?: string
          value_boolean?: boolean | null
          value_number?: number | null
          value_text?: string | null
          value_type: Database["public"]["Enums"]["catalog_attribute_data_type"]
          variant_id?: string | null
        }
        Update: {
          attribute_id?: string | null
          created_at?: string
          id?: string
          name?: string
          product_id?: string
          scope?: Database["public"]["Enums"]["product_attribute_scope"]
          updated_at?: string
          value_boolean?: boolean | null
          value_number?: number | null
          value_text?: string | null
          value_type?: Database["public"]["Enums"]["catalog_attribute_data_type"]
          variant_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "product_attribute_values_attribute_id_fkey"
            columns: ["attribute_id"]
            isOneToOne: false
            referencedRelation: "catalog_attributes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_attribute_values_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_attribute_variant_product_fk"
            columns: ["variant_id", "product_id"]
            isOneToOne: false
            referencedRelation: "product_variants"
            referencedColumns: ["id", "product_id"]
          },
        ]
      }
      product_categories: {
        Row: {
          category_id: string
          created_at: string
          id: string
          product_id: string
        }
        Insert: {
          category_id: string
          created_at?: string
          id?: string
          product_id: string
        }
        Update: {
          category_id?: string
          created_at?: string
          id?: string
          product_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "product_categories_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_categories_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      product_discounts: {
        Row: {
          created_at: string
          created_by: string
          discount_amount: number | null
          discount_currency: string | null
          discount_percentage: number | null
          discount_type: Database["public"]["Enums"]["product_discount_type"]
          ends_at: string | null
          id: string
          product_id: string
          starts_at: string | null
          status: Database["public"]["Enums"]["product_discount_status"]
          updated_at: string
          variant_id: string | null
        }
        Insert: {
          created_at?: string
          created_by: string
          discount_amount?: number | null
          discount_currency?: string | null
          discount_percentage?: number | null
          discount_type: Database["public"]["Enums"]["product_discount_type"]
          ends_at?: string | null
          id?: string
          product_id: string
          starts_at?: string | null
          status?: Database["public"]["Enums"]["product_discount_status"]
          updated_at?: string
          variant_id?: string | null
        }
        Update: {
          created_at?: string
          created_by?: string
          discount_amount?: number | null
          discount_currency?: string | null
          discount_percentage?: number | null
          discount_type?: Database["public"]["Enums"]["product_discount_type"]
          ends_at?: string | null
          id?: string
          product_id?: string
          starts_at?: string | null
          status?: Database["public"]["Enums"]["product_discount_status"]
          updated_at?: string
          variant_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "product_discount_variant_product_fk"
            columns: ["variant_id", "product_id"]
            isOneToOne: false
            referencedRelation: "product_variants"
            referencedColumns: ["id", "product_id"]
          },
          {
            foreignKeyName: "product_discounts_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_discounts_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      product_images: {
        Row: {
          alt: string | null
          created_at: string
          id: string
          is_primary: boolean
          position: number
          product_id: string
          updated_at: string
          url: string
          variant_id: string | null
        }
        Insert: {
          alt?: string | null
          created_at?: string
          id?: string
          is_primary?: boolean
          position?: number
          product_id: string
          updated_at?: string
          url: string
          variant_id?: string | null
        }
        Update: {
          alt?: string | null
          created_at?: string
          id?: string
          is_primary?: boolean
          position?: number
          product_id?: string
          updated_at?: string
          url?: string
          variant_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "product_image_variant_product_fk"
            columns: ["variant_id", "product_id"]
            isOneToOne: false
            referencedRelation: "product_variants"
            referencedColumns: ["id", "product_id"]
          },
          {
            foreignKeyName: "product_images_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      product_option_values: {
        Row: {
          created_at: string
          id: string
          is_active: boolean
          option_id: string
          position: number
          updated_at: string
          value: string
        }
        Insert: {
          created_at?: string
          id?: string
          is_active?: boolean
          option_id: string
          position?: number
          updated_at?: string
          value: string
        }
        Update: {
          created_at?: string
          id?: string
          is_active?: boolean
          option_id?: string
          position?: number
          updated_at?: string
          value?: string
        }
        Relationships: [
          {
            foreignKeyName: "product_option_values_option_id_fkey"
            columns: ["option_id"]
            isOneToOne: false
            referencedRelation: "product_options"
            referencedColumns: ["id"]
          },
        ]
      }
      product_options: {
        Row: {
          attribute_id: string | null
          created_at: string
          id: string
          is_active: boolean
          name: string
          position: number
          product_id: string
          updated_at: string
        }
        Insert: {
          attribute_id?: string | null
          created_at?: string
          id?: string
          is_active?: boolean
          name: string
          position?: number
          product_id: string
          updated_at?: string
        }
        Update: {
          attribute_id?: string | null
          created_at?: string
          id?: string
          is_active?: boolean
          name?: string
          position?: number
          product_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "product_options_attribute_id_fkey"
            columns: ["attribute_id"]
            isOneToOne: false
            referencedRelation: "catalog_attributes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_options_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      product_review_reports: {
        Row: {
          created_at: string
          customer_id: string
          details: string | null
          id: string
          reason: Database["public"]["Enums"]["review_report_reason"]
          review_id: string
          reviewed_at: string | null
          reviewed_by: string | null
          status: Database["public"]["Enums"]["review_report_status"]
        }
        Insert: {
          created_at?: string
          customer_id: string
          details?: string | null
          id?: string
          reason: Database["public"]["Enums"]["review_report_reason"]
          review_id: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: Database["public"]["Enums"]["review_report_status"]
        }
        Update: {
          created_at?: string
          customer_id?: string
          details?: string | null
          id?: string
          reason?: Database["public"]["Enums"]["review_report_reason"]
          review_id?: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: Database["public"]["Enums"]["review_report_status"]
        }
        Relationships: [
          {
            foreignKeyName: "product_review_reports_customer_id_fkey"
            columns: ["customer_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_review_reports_review_id_fkey"
            columns: ["review_id"]
            isOneToOne: false
            referencedRelation: "product_reviews"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_review_reports_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      product_review_responses: {
        Row: {
          created_at: string
          id: string
          response: string
          review_id: string
          updated_at: string
          vendor_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          response: string
          review_id: string
          updated_at?: string
          vendor_id: string
        }
        Update: {
          created_at?: string
          id?: string
          response?: string
          review_id?: string
          updated_at?: string
          vendor_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "product_review_responses_review_id_fkey"
            columns: ["review_id"]
            isOneToOne: true
            referencedRelation: "product_reviews"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_review_responses_vendor_id_fkey"
            columns: ["vendor_id"]
            isOneToOne: false
            referencedRelation: "vendors"
            referencedColumns: ["id"]
          },
        ]
      }
      product_reviews: {
        Row: {
          comment: string | null
          created_at: string
          customer_id: string
          id: string
          images: string[]
          order_id: string
          order_item_id: string
          product_id: string
          rating: number
          status: Database["public"]["Enums"]["review_status"]
          title: string | null
          updated_at: string
        }
        Insert: {
          comment?: string | null
          created_at?: string
          customer_id: string
          id?: string
          images?: string[]
          order_id: string
          order_item_id: string
          product_id: string
          rating: number
          status?: Database["public"]["Enums"]["review_status"]
          title?: string | null
          updated_at?: string
        }
        Update: {
          comment?: string | null
          created_at?: string
          customer_id?: string
          id?: string
          images?: string[]
          order_id?: string
          order_item_id?: string
          product_id?: string
          rating?: number
          status?: Database["public"]["Enums"]["review_status"]
          title?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "product_reviews_customer_id_fkey"
            columns: ["customer_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_reviews_order_item_fk"
            columns: ["order_item_id", "order_id"]
            isOneToOne: false
            referencedRelation: "order_items"
            referencedColumns: ["id", "order_id"]
          },
          {
            foreignKeyName: "product_reviews_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      product_supplier_sources: {
        Row: {
          created_at: string
          id: string
          is_active: boolean
          is_preferred: boolean
          product_variant_id: string
          supplier_product_variant_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          is_active?: boolean
          is_preferred?: boolean
          product_variant_id: string
          supplier_product_variant_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          is_active?: boolean
          is_preferred?: boolean
          product_variant_id?: string
          supplier_product_variant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "product_supplier_sources_product_variant_id_fkey"
            columns: ["product_variant_id"]
            isOneToOne: false
            referencedRelation: "product_variants"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_supplier_sources_supplier_product_variant_id_fkey"
            columns: ["supplier_product_variant_id"]
            isOneToOne: false
            referencedRelation: "supplier_product_variants"
            referencedColumns: ["id"]
          },
        ]
      }
      product_variant_option_selections: {
        Row: {
          created_at: string
          option_id: string
          option_value_id: string
          product_id: string
          variant_id: string
        }
        Insert: {
          created_at?: string
          option_id: string
          option_value_id: string
          product_id: string
          variant_id: string
        }
        Update: {
          created_at?: string
          option_id?: string
          option_value_id?: string
          product_id?: string
          variant_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "selection_option_product_fk"
            columns: ["option_id", "product_id"]
            isOneToOne: false
            referencedRelation: "product_options"
            referencedColumns: ["id", "product_id"]
          },
          {
            foreignKeyName: "selection_value_option_fk"
            columns: ["option_value_id", "option_id"]
            isOneToOne: false
            referencedRelation: "product_option_values"
            referencedColumns: ["id", "option_id"]
          },
          {
            foreignKeyName: "selection_variant_product_fk"
            columns: ["variant_id", "product_id"]
            isOneToOne: false
            referencedRelation: "product_variants"
            referencedColumns: ["id", "product_id"]
          },
        ]
      }
      product_variants: {
        Row: {
          backorder_enabled: boolean
          backorder_max_quantity: number | null
          barcode_type:
            | Database["public"]["Enums"]["product_barcode_type"]
            | null
          barcode_value: string | null
          compare_at_price_amount: number | null
          created_at: string
          id: string
          max_per_customer: number | null
          max_per_order: number | null
          max_total_quantity: number | null
          min_per_order: number
          preorder_enabled: boolean
          preorder_expected_available_at: string | null
          preorder_quantity_limit: number | null
          price_amount: number
          product_id: string
          shipping_overrides: Json | null
          sku: string
          sku_source: Database["public"]["Enums"]["product_sku_source"]
          status: Database["public"]["Enums"]["product_variant_status"]
          title: string
          updated_at: string
        }
        Insert: {
          backorder_enabled?: boolean
          backorder_max_quantity?: number | null
          barcode_type?:
            | Database["public"]["Enums"]["product_barcode_type"]
            | null
          barcode_value?: string | null
          compare_at_price_amount?: number | null
          created_at?: string
          id?: string
          max_per_customer?: number | null
          max_per_order?: number | null
          max_total_quantity?: number | null
          min_per_order?: number
          preorder_enabled?: boolean
          preorder_expected_available_at?: string | null
          preorder_quantity_limit?: number | null
          price_amount: number
          product_id: string
          shipping_overrides?: Json | null
          sku: string
          sku_source?: Database["public"]["Enums"]["product_sku_source"]
          status?: Database["public"]["Enums"]["product_variant_status"]
          title: string
          updated_at?: string
        }
        Update: {
          backorder_enabled?: boolean
          backorder_max_quantity?: number | null
          barcode_type?:
            | Database["public"]["Enums"]["product_barcode_type"]
            | null
          barcode_value?: string | null
          compare_at_price_amount?: number | null
          created_at?: string
          id?: string
          max_per_customer?: number | null
          max_per_order?: number | null
          max_total_quantity?: number | null
          min_per_order?: number
          preorder_enabled?: boolean
          preorder_expected_available_at?: string | null
          preorder_quantity_limit?: number | null
          price_amount?: number
          product_id?: string
          shipping_overrides?: Json | null
          sku?: string
          sku_source?: Database["public"]["Enums"]["product_sku_source"]
          status?: Database["public"]["Enums"]["product_variant_status"]
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "product_variants_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      products: {
        Row: {
          base_currency: string
          created_at: string
          description: string
          dimension_height: number | null
          dimension_length: number | null
          dimension_unit:
            | Database["public"]["Enums"]["product_dimension_unit"]
            | null
          dimension_width: number | null
          id: string
          name: string
          owner_type: Database["public"]["Enums"]["product_ownership_type"]
          slug: string
          status: Database["public"]["Enums"]["product_status"]
          type: Database["public"]["Enums"]["product_type"]
          updated_at: string
          vendor_id: string | null
          weight_unit: Database["public"]["Enums"]["product_weight_unit"] | null
          weight_value: number | null
        }
        Insert: {
          base_currency: string
          created_at?: string
          description?: string
          dimension_height?: number | null
          dimension_length?: number | null
          dimension_unit?:
            | Database["public"]["Enums"]["product_dimension_unit"]
            | null
          dimension_width?: number | null
          id?: string
          name: string
          owner_type: Database["public"]["Enums"]["product_ownership_type"]
          slug: string
          status?: Database["public"]["Enums"]["product_status"]
          type: Database["public"]["Enums"]["product_type"]
          updated_at?: string
          vendor_id?: string | null
          weight_unit?:
            | Database["public"]["Enums"]["product_weight_unit"]
            | null
          weight_value?: number | null
        }
        Update: {
          base_currency?: string
          created_at?: string
          description?: string
          dimension_height?: number | null
          dimension_length?: number | null
          dimension_unit?:
            | Database["public"]["Enums"]["product_dimension_unit"]
            | null
          dimension_width?: number | null
          id?: string
          name?: string
          owner_type?: Database["public"]["Enums"]["product_ownership_type"]
          slug?: string
          status?: Database["public"]["Enums"]["product_status"]
          type?: Database["public"]["Enums"]["product_type"]
          updated_at?: string
          vendor_id?: string | null
          weight_unit?:
            | Database["public"]["Enums"]["product_weight_unit"]
            | null
          weight_value?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "products_vendor_id_fkey"
            columns: ["vendor_id"]
            isOneToOne: false
            referencedRelation: "vendors"
            referencedColumns: ["id"]
          },
        ]
      }
      return_eligibility_policies: {
        Row: {
          created_at: string
          effective_from: string
          effective_until: string | null
          id: string
          is_active: boolean
          name: string
          return_eligibility_days: number
          updated_at: string
        }
        Insert: {
          created_at?: string
          effective_from?: string
          effective_until?: string | null
          id?: string
          is_active?: boolean
          name: string
          return_eligibility_days: number
          updated_at?: string
        }
        Update: {
          created_at?: string
          effective_from?: string
          effective_until?: string | null
          id?: string
          is_active?: boolean
          name?: string
          return_eligibility_days?: number
          updated_at?: string
        }
        Relationships: []
      }
      return_items: {
        Row: {
          approved_quantity: number | null
          created_at: string
          id: string
          order_id: string
          order_item_id: string
          reason: Database["public"]["Enums"]["return_reason"]
          reason_details: string | null
          requested_quantity: number
          resolution: Database["public"]["Enums"]["return_resolution"] | null
          resolution_notes: string | null
          return_id: string
          updated_at: string
        }
        Insert: {
          approved_quantity?: number | null
          created_at?: string
          id?: string
          order_id: string
          order_item_id: string
          reason: Database["public"]["Enums"]["return_reason"]
          reason_details?: string | null
          requested_quantity: number
          resolution?: Database["public"]["Enums"]["return_resolution"] | null
          resolution_notes?: string | null
          return_id: string
          updated_at?: string
        }
        Update: {
          approved_quantity?: number | null
          created_at?: string
          id?: string
          order_id?: string
          order_item_id?: string
          reason?: Database["public"]["Enums"]["return_reason"]
          reason_details?: string | null
          requested_quantity?: number
          resolution?: Database["public"]["Enums"]["return_resolution"] | null
          resolution_notes?: string | null
          return_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "return_items_order_item_fk"
            columns: ["order_item_id", "order_id"]
            isOneToOne: false
            referencedRelation: "order_items"
            referencedColumns: ["id", "order_id"]
          },
          {
            foreignKeyName: "return_items_return_order_fk"
            columns: ["return_id", "order_id"]
            isOneToOne: false
            referencedRelation: "returns"
            referencedColumns: ["id", "order_id"]
          },
        ]
      }
      returns: {
        Row: {
          created_at: string
          customer_id: string
          customer_notes: string | null
          id: string
          order_id: string
          received_at: string | null
          requested_at: string
          resolved_at: string | null
          return_number: string
          review_notes: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          status: Database["public"]["Enums"]["return_status"]
          updated_at: string
        }
        Insert: {
          created_at?: string
          customer_id: string
          customer_notes?: string | null
          id?: string
          order_id: string
          received_at?: string | null
          requested_at?: string
          resolved_at?: string | null
          return_number?: string
          review_notes?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: Database["public"]["Enums"]["return_status"]
          updated_at?: string
        }
        Update: {
          created_at?: string
          customer_id?: string
          customer_notes?: string | null
          id?: string
          order_id?: string
          received_at?: string | null
          requested_at?: string
          resolved_at?: string | null
          return_number?: string
          review_notes?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: Database["public"]["Enums"]["return_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "returns_order_customer_fk"
            columns: ["order_id", "customer_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id", "customer_id"]
          },
          {
            foreignKeyName: "returns_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      role_permissions: {
        Row: {
          permission_key: string
          role: Database["public"]["Enums"]["platform_access_role"]
        }
        Insert: {
          permission_key: string
          role: Database["public"]["Enums"]["platform_access_role"]
        }
        Update: {
          permission_key?: string
          role?: Database["public"]["Enums"]["platform_access_role"]
        }
        Relationships: [
          {
            foreignKeyName: "role_permissions_permission_key_fkey"
            columns: ["permission_key"]
            isOneToOne: false
            referencedRelation: "platform_permissions"
            referencedColumns: ["key"]
          },
        ]
      }
      shipment_items: {
        Row: {
          created_at: string
          fulfillment_item_id: string
          id: string
          order_item_id: string
          quantity: number
          shipment_id: string
        }
        Insert: {
          created_at?: string
          fulfillment_item_id: string
          id?: string
          order_item_id: string
          quantity: number
          shipment_id: string
        }
        Update: {
          created_at?: string
          fulfillment_item_id?: string
          id?: string
          order_item_id?: string
          quantity?: number
          shipment_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "shipment_items_fulfillment_item_id_fkey"
            columns: ["fulfillment_item_id"]
            isOneToOne: false
            referencedRelation: "fulfillment_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "shipment_items_order_item_id_fkey"
            columns: ["order_item_id"]
            isOneToOne: false
            referencedRelation: "order_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "shipment_items_shipment_id_fkey"
            columns: ["shipment_id"]
            isOneToOne: false
            referencedRelation: "shipments"
            referencedColumns: ["id"]
          },
        ]
      }
      shipment_tracking_events: {
        Row: {
          created_at: string
          description: string
          id: string
          location: string | null
          occurred_at: string
          shipment_id: string
          status: Database["public"]["Enums"]["shipment_status"]
        }
        Insert: {
          created_at?: string
          description: string
          id?: string
          location?: string | null
          occurred_at: string
          shipment_id: string
          status: Database["public"]["Enums"]["shipment_status"]
        }
        Update: {
          created_at?: string
          description?: string
          id?: string
          location?: string | null
          occurred_at?: string
          shipment_id?: string
          status?: Database["public"]["Enums"]["shipment_status"]
        }
        Relationships: [
          {
            foreignKeyName: "shipment_tracking_events_shipment_id_fkey"
            columns: ["shipment_id"]
            isOneToOne: false
            referencedRelation: "shipments"
            referencedColumns: ["id"]
          },
        ]
      }
      shipments: {
        Row: {
          carrier: string | null
          created_at: string
          delivered_at: string | null
          fulfillment_id: string
          id: string
          shipped_at: string | null
          status: Database["public"]["Enums"]["shipment_status"]
          tracking_number: string | null
          tracking_url: string | null
          updated_at: string
        }
        Insert: {
          carrier?: string | null
          created_at?: string
          delivered_at?: string | null
          fulfillment_id: string
          id?: string
          shipped_at?: string | null
          status?: Database["public"]["Enums"]["shipment_status"]
          tracking_number?: string | null
          tracking_url?: string | null
          updated_at?: string
        }
        Update: {
          carrier?: string | null
          created_at?: string
          delivered_at?: string | null
          fulfillment_id?: string
          id?: string
          shipped_at?: string | null
          status?: Database["public"]["Enums"]["shipment_status"]
          tracking_number?: string | null
          tracking_url?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "shipments_fulfillment_id_fkey"
            columns: ["fulfillment_id"]
            isOneToOne: false
            referencedRelation: "fulfillments"
            referencedColumns: ["id"]
          },
        ]
      }
      shipping_methods: {
        Row: {
          created_at: string
          description: string | null
          id: string
          is_active: boolean
          name: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name?: string
          updated_at?: string
        }
        Relationships: []
      }
      shipping_rates: {
        Row: {
          amount: number
          created_at: string
          currency: string
          destination_country: string
          estimated_max_days: number | null
          estimated_min_days: number | null
          id: string
          is_active: boolean
          name: string
          origin_country: string | null
          shipping_method_id: string
          source: Database["public"]["Enums"]["shipping_rate_source"]
          updated_at: string
        }
        Insert: {
          amount: number
          created_at?: string
          currency: string
          destination_country: string
          estimated_max_days?: number | null
          estimated_min_days?: number | null
          id?: string
          is_active?: boolean
          name: string
          origin_country?: string | null
          shipping_method_id: string
          source: Database["public"]["Enums"]["shipping_rate_source"]
          updated_at?: string
        }
        Update: {
          amount?: number
          created_at?: string
          currency?: string
          destination_country?: string
          estimated_max_days?: number | null
          estimated_min_days?: number | null
          id?: string
          is_active?: boolean
          name?: string
          origin_country?: string | null
          shipping_method_id?: string
          source?: Database["public"]["Enums"]["shipping_rate_source"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "shipping_rates_shipping_method_id_fkey"
            columns: ["shipping_method_id"]
            isOneToOne: false
            referencedRelation: "shipping_methods"
            referencedColumns: ["id"]
          },
        ]
      }
      shipping_selections: {
        Row: {
          created_at: string
          fulfillment_id: string
          id: string
          rate_snapshot: Json
          selected_at: string
          shipping_method_id: string
          shipping_rate_id: string
        }
        Insert: {
          created_at?: string
          fulfillment_id: string
          id?: string
          rate_snapshot: Json
          selected_at?: string
          shipping_method_id: string
          shipping_rate_id: string
        }
        Update: {
          created_at?: string
          fulfillment_id?: string
          id?: string
          rate_snapshot?: Json
          selected_at?: string
          shipping_method_id?: string
          shipping_rate_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "shipping_selection_rate_method_fkey"
            columns: ["shipping_rate_id", "shipping_method_id"]
            isOneToOne: false
            referencedRelation: "shipping_rates"
            referencedColumns: ["id", "shipping_method_id"]
          },
          {
            foreignKeyName: "shipping_selections_fulfillment_id_fkey"
            columns: ["fulfillment_id"]
            isOneToOne: true
            referencedRelation: "fulfillments"
            referencedColumns: ["id"]
          },
        ]
      }
      supplier_product_variants: {
        Row: {
          available_quantity: number | null
          cost_amount: number
          created_at: string
          currency: string
          external_variant_id: string
          id: string
          last_synced_at: string | null
          sku: string | null
          status: Database["public"]["Enums"]["supplier_product_status"]
          supplier_product_id: string
          title: string
          updated_at: string
        }
        Insert: {
          available_quantity?: number | null
          cost_amount: number
          created_at?: string
          currency: string
          external_variant_id: string
          id?: string
          last_synced_at?: string | null
          sku?: string | null
          status?: Database["public"]["Enums"]["supplier_product_status"]
          supplier_product_id: string
          title: string
          updated_at?: string
        }
        Update: {
          available_quantity?: number | null
          cost_amount?: number
          created_at?: string
          currency?: string
          external_variant_id?: string
          id?: string
          last_synced_at?: string | null
          sku?: string | null
          status?: Database["public"]["Enums"]["supplier_product_status"]
          supplier_product_id?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "supplier_product_variants_supplier_product_id_fkey"
            columns: ["supplier_product_id"]
            isOneToOne: false
            referencedRelation: "supplier_products"
            referencedColumns: ["id"]
          },
        ]
      }
      supplier_products: {
        Row: {
          created_at: string
          external_product_id: string
          external_url: string
          id: string
          last_synced_at: string | null
          status: Database["public"]["Enums"]["supplier_product_status"]
          supplier_id: string
          title: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          external_product_id: string
          external_url: string
          id?: string
          last_synced_at?: string | null
          status?: Database["public"]["Enums"]["supplier_product_status"]
          supplier_id: string
          title: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          external_product_id?: string
          external_url?: string
          id?: string
          last_synced_at?: string | null
          status?: Database["public"]["Enums"]["supplier_product_status"]
          supplier_id?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "supplier_products_supplier_id_fkey"
            columns: ["supplier_id"]
            isOneToOne: false
            referencedRelation: "suppliers"
            referencedColumns: ["id"]
          },
        ]
      }
      suppliers: {
        Row: {
          created_at: string
          id: string
          name: string
          owner_type: Database["public"]["Enums"]["product_ownership_type"]
          provider: Database["public"]["Enums"]["supplier_provider"]
          status: Database["public"]["Enums"]["supplier_status"]
          updated_at: string
          vendor_id: string | null
        }
        Insert: {
          created_at?: string
          id?: string
          name: string
          owner_type: Database["public"]["Enums"]["product_ownership_type"]
          provider: Database["public"]["Enums"]["supplier_provider"]
          status?: Database["public"]["Enums"]["supplier_status"]
          updated_at?: string
          vendor_id?: string | null
        }
        Update: {
          created_at?: string
          id?: string
          name?: string
          owner_type?: Database["public"]["Enums"]["product_ownership_type"]
          provider?: Database["public"]["Enums"]["supplier_provider"]
          status?: Database["public"]["Enums"]["supplier_status"]
          updated_at?: string
          vendor_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "suppliers_vendor_id_fkey"
            columns: ["vendor_id"]
            isOneToOne: false
            referencedRelation: "vendors"
            referencedColumns: ["id"]
          },
        ]
      }
      users: {
        Row: {
          avatar_url: string | null
          created_at: string
          deletion_requested_at: string | null
          display_name: string | null
          email: string
          id: string
          status: Database["public"]["Enums"]["account_status"]
          status_reason: string | null
          updated_at: string
        }
        Insert: {
          avatar_url?: string | null
          created_at?: string
          deletion_requested_at?: string | null
          display_name?: string | null
          email: string
          id: string
          status?: Database["public"]["Enums"]["account_status"]
          status_reason?: string | null
          updated_at?: string
        }
        Update: {
          avatar_url?: string | null
          created_at?: string
          deletion_requested_at?: string | null
          display_name?: string | null
          email?: string
          id?: string
          status?: Database["public"]["Enums"]["account_status"]
          status_reason?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      vendor_application_documents: {
        Row: {
          application_id: string
          content_type: string
          document_type: string
          file_size_bytes: number
          id: string
          original_file_name: string
          storage_path: string
          uploaded_at: string
        }
        Insert: {
          application_id: string
          content_type: string
          document_type: string
          file_size_bytes: number
          id?: string
          original_file_name: string
          storage_path: string
          uploaded_at?: string
        }
        Update: {
          application_id?: string
          content_type?: string
          document_type?: string
          file_size_bytes?: number
          id?: string
          original_file_name?: string
          storage_path?: string
          uploaded_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "vendor_application_documents_application_id_fkey"
            columns: ["application_id"]
            isOneToOne: false
            referencedRelation: "vendor_applications"
            referencedColumns: ["id"]
          },
        ]
      }
      vendor_application_settings: {
        Row: {
          max_attempts: number
          singleton: boolean
          updated_at: string
        }
        Insert: {
          max_attempts?: number
          singleton?: boolean
          updated_at?: string
        }
        Update: {
          max_attempts?: number
          singleton?: boolean
          updated_at?: string
        }
        Relationships: []
      }
      vendor_applications: {
        Row: {
          applicant_id: string
          attempt_number: number
          business_email: string
          business_name: string
          business_phone: string
          business_type: string
          country_code: string
          created_at: string
          id: string
          review_notes: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          status: Database["public"]["Enums"]["vendor_application_status"]
          submitted_at: string
          updated_at: string
        }
        Insert: {
          applicant_id: string
          attempt_number: number
          business_email: string
          business_name: string
          business_phone: string
          business_type: string
          country_code: string
          created_at?: string
          id?: string
          review_notes?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: Database["public"]["Enums"]["vendor_application_status"]
          submitted_at?: string
          updated_at?: string
        }
        Update: {
          applicant_id?: string
          attempt_number?: number
          business_email?: string
          business_name?: string
          business_phone?: string
          business_type?: string
          country_code?: string
          created_at?: string
          id?: string
          review_notes?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: Database["public"]["Enums"]["vendor_application_status"]
          submitted_at?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "vendor_applications_applicant_id_fkey"
            columns: ["applicant_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vendor_applications_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      vendor_closure_requests: {
        Row: {
          created_at: string
          id: string
          reason: string
          requested_at: string
          requested_by: string
          review_notes: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          status: Database["public"]["Enums"]["vendor_closure_request_status"]
          updated_at: string
          vendor_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          reason: string
          requested_at?: string
          requested_by: string
          review_notes?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: Database["public"]["Enums"]["vendor_closure_request_status"]
          updated_at?: string
          vendor_id: string
        }
        Update: {
          created_at?: string
          id?: string
          reason?: string
          requested_at?: string
          requested_by?: string
          review_notes?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: Database["public"]["Enums"]["vendor_closure_request_status"]
          updated_at?: string
          vendor_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "vendor_closure_requests_requested_by_fkey"
            columns: ["requested_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vendor_closure_requests_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vendor_closure_requests_vendor_id_fkey"
            columns: ["vendor_id"]
            isOneToOne: false
            referencedRelation: "vendors"
            referencedColumns: ["id"]
          },
        ]
      }
      vendor_commission_overrides: {
        Row: {
          created_at: string
          effective_from: string
          effective_until: string | null
          id: string
          is_active: boolean
          rate_basis_points: number
          updated_at: string
          vendor_id: string
        }
        Insert: {
          created_at?: string
          effective_from?: string
          effective_until?: string | null
          id?: string
          is_active?: boolean
          rate_basis_points: number
          updated_at?: string
          vendor_id: string
        }
        Update: {
          created_at?: string
          effective_from?: string
          effective_until?: string | null
          id?: string
          is_active?: boolean
          rate_basis_points?: number
          updated_at?: string
          vendor_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "vendor_commission_overrides_vendor_id_fkey"
            columns: ["vendor_id"]
            isOneToOne: false
            referencedRelation: "vendors"
            referencedColumns: ["id"]
          },
        ]
      }
      vendor_earning_holds: {
        Row: {
          created_at: string
          earning_id: string
          id: string
          payment_refund_id: string
          released_at: string | null
          released_by: string | null
          resolution_note: string | null
          status: string
        }
        Insert: {
          created_at?: string
          earning_id: string
          id?: string
          payment_refund_id: string
          released_at?: string | null
          released_by?: string | null
          resolution_note?: string | null
          status?: string
        }
        Update: {
          created_at?: string
          earning_id?: string
          id?: string
          payment_refund_id?: string
          released_at?: string | null
          released_by?: string | null
          resolution_note?: string | null
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "vendor_earning_holds_earning_id_fkey"
            columns: ["earning_id"]
            isOneToOne: false
            referencedRelation: "vendor_earnings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vendor_earning_holds_payment_refund_id_fkey"
            columns: ["payment_refund_id"]
            isOneToOne: false
            referencedRelation: "payment_refunds"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vendor_earning_holds_released_by_fkey"
            columns: ["released_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      vendor_earnings: {
        Row: {
          available_at: string | null
          commission_amount: number
          created_at: string
          currency: string
          deduction_amount: number
          delivery_completed_at: string | null
          gross_amount: number
          id: string
          net_amount: number
          order_id: string
          order_item_id: string
          status: Database["public"]["Enums"]["vendor_earning_status"]
          updated_at: string
          vendor_id: string
        }
        Insert: {
          available_at?: string | null
          commission_amount?: number
          created_at?: string
          currency: string
          deduction_amount?: number
          delivery_completed_at?: string | null
          gross_amount: number
          id?: string
          net_amount: number
          order_id: string
          order_item_id: string
          status?: Database["public"]["Enums"]["vendor_earning_status"]
          updated_at?: string
          vendor_id: string
        }
        Update: {
          available_at?: string | null
          commission_amount?: number
          created_at?: string
          currency?: string
          deduction_amount?: number
          delivery_completed_at?: string | null
          gross_amount?: number
          id?: string
          net_amount?: number
          order_id?: string
          order_item_id?: string
          status?: Database["public"]["Enums"]["vendor_earning_status"]
          updated_at?: string
          vendor_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "vendor_earnings_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vendor_earnings_order_item_fk"
            columns: ["order_item_id", "order_id"]
            isOneToOne: false
            referencedRelation: "order_items"
            referencedColumns: ["id", "order_id"]
          },
          {
            foreignKeyName: "vendor_earnings_vendor_id_fkey"
            columns: ["vendor_id"]
            isOneToOne: false
            referencedRelation: "vendors"
            referencedColumns: ["id"]
          },
        ]
      }
      vendor_memberships: {
        Row: {
          created_at: string
          id: string
          role: string
          updated_at: string
          user_id: string
          vendor_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          role?: string
          updated_at?: string
          user_id: string
          vendor_id: string
        }
        Update: {
          created_at?: string
          id?: string
          role?: string
          updated_at?: string
          user_id?: string
          vendor_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "vendor_memberships_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vendor_memberships_vendor_id_fkey"
            columns: ["vendor_id"]
            isOneToOne: true
            referencedRelation: "vendors"
            referencedColumns: ["id"]
          },
        ]
      }
      vendor_payout_account_credentials: {
        Row: {
          created_at: string
          payout_account_id: string
          provider: string
          provider_recipient_token: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          payout_account_id: string
          provider: string
          provider_recipient_token: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          payout_account_id?: string
          provider?: string
          provider_recipient_token?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "vendor_payout_account_credentials_payout_account_id_fkey"
            columns: ["payout_account_id"]
            isOneToOne: true
            referencedRelation: "vendor_payout_accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      vendor_payout_accounts: {
        Row: {
          account_name: string
          account_number_last4: string
          bank_code: string
          bank_name: string
          country_code: string
          created_at: string
          created_by: string
          currency: string
          id: string
          is_default: boolean
          provider: string
          provider_account_id: string | null
          status: Database["public"]["Enums"]["payout_account_status"]
          updated_at: string
          vendor_id: string
          verified_at: string | null
        }
        Insert: {
          account_name: string
          account_number_last4: string
          bank_code: string
          bank_name: string
          country_code: string
          created_at?: string
          created_by: string
          currency: string
          id?: string
          is_default?: boolean
          provider: string
          provider_account_id?: string | null
          status?: Database["public"]["Enums"]["payout_account_status"]
          updated_at?: string
          vendor_id: string
          verified_at?: string | null
        }
        Update: {
          account_name?: string
          account_number_last4?: string
          bank_code?: string
          bank_name?: string
          country_code?: string
          created_at?: string
          created_by?: string
          currency?: string
          id?: string
          is_default?: boolean
          provider?: string
          provider_account_id?: string | null
          status?: Database["public"]["Enums"]["payout_account_status"]
          updated_at?: string
          vendor_id?: string
          verified_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "vendor_payout_accounts_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vendor_payout_accounts_vendor_id_fkey"
            columns: ["vendor_id"]
            isOneToOne: false
            referencedRelation: "vendors"
            referencedColumns: ["id"]
          },
        ]
      }
      vendor_payout_items: {
        Row: {
          amount: number
          created_at: string
          earning_id: string
          id: string
          payout_id: string
        }
        Insert: {
          amount: number
          created_at?: string
          earning_id: string
          id?: string
          payout_id: string
        }
        Update: {
          amount?: number
          created_at?: string
          earning_id?: string
          id?: string
          payout_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "vendor_payout_items_earning_id_fkey"
            columns: ["earning_id"]
            isOneToOne: false
            referencedRelation: "vendor_earnings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vendor_payout_items_payout_id_fkey"
            columns: ["payout_id"]
            isOneToOne: false
            referencedRelation: "vendor_payouts"
            referencedColumns: ["id"]
          },
        ]
      }
      vendor_payouts: {
        Row: {
          amount: number
          completed_at: string | null
          created_at: string
          currency: string
          destination_snapshot: Json | null
          failure_reason: string | null
          id: string
          idempotency_key: string
          payout_account_id: string | null
          processed_at: string | null
          provider: string | null
          provider_reference: string | null
          requested_at: string
          status: Database["public"]["Enums"]["vendor_payout_status"]
          updated_at: string
          vendor_id: string
        }
        Insert: {
          amount: number
          completed_at?: string | null
          created_at?: string
          currency: string
          destination_snapshot?: Json | null
          failure_reason?: string | null
          id?: string
          idempotency_key: string
          payout_account_id?: string | null
          processed_at?: string | null
          provider?: string | null
          provider_reference?: string | null
          requested_at?: string
          status?: Database["public"]["Enums"]["vendor_payout_status"]
          updated_at?: string
          vendor_id: string
        }
        Update: {
          amount?: number
          completed_at?: string | null
          created_at?: string
          currency?: string
          destination_snapshot?: Json | null
          failure_reason?: string | null
          id?: string
          idempotency_key?: string
          payout_account_id?: string | null
          processed_at?: string | null
          provider?: string | null
          provider_reference?: string | null
          requested_at?: string
          status?: Database["public"]["Enums"]["vendor_payout_status"]
          updated_at?: string
          vendor_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "vendor_payouts_payout_account_id_fkey"
            columns: ["payout_account_id"]
            isOneToOne: false
            referencedRelation: "vendor_payout_accounts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vendor_payouts_vendor_id_fkey"
            columns: ["vendor_id"]
            isOneToOne: false
            referencedRelation: "vendors"
            referencedColumns: ["id"]
          },
        ]
      }
      vendor_verification_documents: {
        Row: {
          content_type: string
          created_at: string
          document_type: string
          file_size_bytes: number
          id: string
          original_file_name: string
          storage_path: string
          uploaded_at: string
          verification_id: string
        }
        Insert: {
          content_type: string
          created_at?: string
          document_type: string
          file_size_bytes: number
          id?: string
          original_file_name: string
          storage_path: string
          uploaded_at?: string
          verification_id: string
        }
        Update: {
          content_type?: string
          created_at?: string
          document_type?: string
          file_size_bytes?: number
          id?: string
          original_file_name?: string
          storage_path?: string
          uploaded_at?: string
          verification_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "vendor_verification_documents_verification_id_fkey"
            columns: ["verification_id"]
            isOneToOne: false
            referencedRelation: "vendor_verifications"
            referencedColumns: ["id"]
          },
        ]
      }
      vendor_verifications: {
        Row: {
          created_at: string
          id: string
          review_notes: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          status: Database["public"]["Enums"]["business_verification_status"]
          submitted_at: string | null
          updated_at: string
          vendor_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          review_notes?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: Database["public"]["Enums"]["business_verification_status"]
          submitted_at?: string | null
          updated_at?: string
          vendor_id: string
        }
        Update: {
          created_at?: string
          id?: string
          review_notes?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: Database["public"]["Enums"]["business_verification_status"]
          submitted_at?: string | null
          updated_at?: string
          vendor_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "vendor_verifications_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vendor_verifications_vendor_id_fkey"
            columns: ["vendor_id"]
            isOneToOne: true
            referencedRelation: "vendors"
            referencedColumns: ["id"]
          },
        ]
      }
      vendors: {
        Row: {
          application_id: string
          approved_at: string
          business_email: string
          business_phone: string
          business_type: string
          country_code: string
          created_at: string
          created_by: string
          description: string | null
          id: string
          logo_url: string | null
          name: string
          slug: string
          status: Database["public"]["Enums"]["vendor_status"]
          updated_at: string
        }
        Insert: {
          application_id: string
          approved_at?: string
          business_email: string
          business_phone: string
          business_type: string
          country_code: string
          created_at?: string
          created_by: string
          description?: string | null
          id?: string
          logo_url?: string | null
          name: string
          slug: string
          status?: Database["public"]["Enums"]["vendor_status"]
          updated_at?: string
        }
        Update: {
          application_id?: string
          approved_at?: string
          business_email?: string
          business_phone?: string
          business_type?: string
          country_code?: string
          created_at?: string
          created_by?: string
          description?: string | null
          id?: string
          logo_url?: string | null
          name?: string
          slug?: string
          status?: Database["public"]["Enums"]["vendor_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "vendors_application_id_fkey"
            columns: ["application_id"]
            isOneToOne: true
            referencedRelation: "vendor_applications"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vendors_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      approve_vendor_application: {
        Args: {
          p_application_id: string
          p_review_notes?: string
          p_vendor_slug: string
        }
        Returns: string
      }
      authorize_digital_download: {
        Args: { p_access_id: string }
        Returns: string
      }
      can_manage_digital_asset_storage: {
        Args: { p_object_name: string }
        Returns: boolean
      }
      can_manage_inventory_location: {
        Args: { p_location_id: string }
        Returns: boolean
      }
      can_manage_product: { Args: { p_product_id: string }; Returns: boolean }
      can_manage_supplier: { Args: { p_supplier_id: string }; Returns: boolean }
      create_vendor_earning_holds_for_refund: {
        Args: { p_payment_refund_id: string }
        Returns: undefined
      }
      grant_digital_access_for_order: {
        Args: { p_order_id: string }
        Returns: number
      }
      is_active_platform_admin: { Args: never; Returns: boolean }
      is_active_super_admin: { Args: never; Returns: boolean }
      is_vendor_owner: { Args: { p_vendor_id: string }; Returns: boolean }
      moderate_product_review: {
        Args: {
          p_review_id: string
          p_status: Database["public"]["Enums"]["review_status"]
        }
        Returns: undefined
      }
      moderate_product_review_report: {
        Args: {
          p_report_id: string
          p_status: Database["public"]["Enums"]["review_report_status"]
        }
        Returns: undefined
      }
      recalculate_vendor_earning: {
        Args: { p_order_item_id: string }
        Returns: undefined
      }
      reject_vendor_application: {
        Args: { p_application_id: string; p_review_notes: string }
        Returns: undefined
      }
      release_eligible_vendor_earnings: { Args: never; Returns: number }
      request_vendor_payout: {
        Args: {
          p_earning_ids: string[]
          p_idempotency_key: string
          p_payout_account_id: string
          p_vendor_id: string
        }
        Returns: string
      }
      resolve_vendor_earning_hold: {
        Args: { p_hold_id: string; p_resolution_note: string }
        Returns: undefined
      }
      review_vendor_closure_request: {
        Args: {
          p_decision: Database["public"]["Enums"]["vendor_closure_request_status"]
          p_request_id: string
          p_review_notes?: string
        }
        Returns: undefined
      }
      review_vendor_verification: {
        Args: {
          p_decision: Database["public"]["Enums"]["business_verification_status"]
          p_review_notes?: string
          p_verification_id: string
        }
        Returns: undefined
      }
      set_vendor_status: {
        Args: {
          p_reason: string
          p_status: Database["public"]["Enums"]["vendor_status"]
          p_vendor_id: string
        }
        Returns: undefined
      }
      submit_product_review: {
        Args: {
          p_comment?: string
          p_images?: string[]
          p_order_item_id: string
          p_rating: number
          p_title?: string
        }
        Returns: string
      }
      submit_vendor_application: {
        Args: {
          p_business_email: string
          p_business_name: string
          p_business_phone: string
          p_business_type: string
          p_country_code: string
        }
        Returns: string
      }
      submit_vendor_closure_request: {
        Args: { p_reason: string; p_vendor_id: string }
        Returns: string
      }
      submit_vendor_verification: {
        Args: { p_verification_id: string }
        Returns: undefined
      }
      update_vendor_payout_status: {
        Args: {
          p_failure_reason?: string
          p_new_status: Database["public"]["Enums"]["vendor_payout_status"]
          p_payout_id: string
          p_provider?: string
          p_provider_reference?: string
        }
        Returns: undefined
      }
      upsert_vendor_review_response: {
        Args: { p_response: string; p_review_id: string }
        Returns: string
      }
      withdraw_vendor_application: {
        Args: { p_application_id: string }
        Returns: undefined
      }
      withdraw_vendor_closure_request: {
        Args: { p_request_id: string }
        Returns: undefined
      }
    }
    Enums: {
      access_status: "pending" | "active" | "suspended" | "revoked"
      account_status:
        | "active"
        | "suspended"
        | "deactivated"
        | "pending_deletion"
      business_verification_status:
        | "not_submitted"
        | "pending"
        | "verified"
        | "rejected"
      catalog_attribute_data_type: "text" | "number" | "boolean"
      catalog_attribute_usage: "variant_option" | "descriptive" | "both"
      category_status: "active" | "inactive"
      checkout_status:
        | "active"
        | "processing"
        | "completed"
        | "expired"
        | "cancelled"
      digital_asset_type:
        | "pdf"
        | "ebook"
        | "image"
        | "audio"
        | "video"
        | "archive"
        | "other"
      fulfillment_source_type: "platform" | "vendor"
      fulfillment_status:
        | "pending"
        | "awaiting_supplier"
        | "processing"
        | "shipped"
        | "delivered"
        | "failed"
        | "cancelled"
      inventory_adjustment_reason:
        | "restock"
        | "sale"
        | "return"
        | "damage"
        | "correction"
      inventory_location_ownership_type: "platform" | "vendor"
      inventory_location_type:
        | "warehouse"
        | "store"
        | "fulfillment_center"
        | "other"
      inventory_reservation_status:
        | "active"
        | "committed"
        | "released"
        | "expired"
      inventory_tracking_mode: "manual" | "hybrid"
      order_status:
        | "pending_payment"
        | "paid"
        | "processing"
        | "partially_fulfilled"
        | "fulfilled"
        | "cancelled"
        | "refunded"
        | "partially_refunded"
      payment_provider: "stripe" | "paystack" | "paypal"
      payment_refund_status: "pending" | "succeeded" | "failed"
      payment_status:
        | "pending"
        | "processing"
        | "succeeded"
        | "failed"
        | "cancelled"
        | "partially_refunded"
        | "refunded"
      payout_account_status:
        | "pending_verification"
        | "verified"
        | "rejected"
        | "disabled"
      platform_access_role: "admin" | "super_admin"
      product_attribute_scope: "product" | "variant"
      product_barcode_type: "upc" | "ean" | "gtin"
      product_dimension_unit: "mm" | "cm" | "in"
      product_discount_status:
        | "draft"
        | "scheduled"
        | "active"
        | "expired"
        | "disabled"
      product_discount_type: "percentage" | "fixed_amount"
      product_ownership_type: "platform" | "vendor"
      product_sku_source: "generated" | "manual"
      product_status:
        | "draft"
        | "pending_review"
        | "active"
        | "rejected"
        | "archived"
      product_type: "physical" | "digital"
      product_variant_status:
        | "active"
        | "inactive"
        | "discontinued"
        | "archived"
      product_weight_unit: "g" | "kg" | "oz" | "lb"
      return_reason:
        | "damaged"
        | "defective"
        | "wrong_item"
        | "missing_parts"
        | "not_as_described"
        | "wrong_size"
        | "changed_mind"
        | "other"
      return_resolution: "refund" | "replacement" | "no_refund"
      return_status:
        | "requested"
        | "approved"
        | "rejected"
        | "awaiting_shipment"
        | "in_transit"
        | "received"
        | "inspecting"
        | "completed"
        | "cancelled"
      review_report_reason:
        | "spam"
        | "abusive"
        | "conflict_of_interest"
        | "false_information"
        | "other"
      review_report_status: "pending" | "resolved" | "dismissed"
      review_status: "pending" | "published" | "rejected" | "hidden"
      shipment_status:
        | "pending"
        | "label_created"
        | "in_transit"
        | "out_for_delivery"
        | "delivered"
        | "exception"
        | "returned"
      shipping_rate_source: "supplier" | "platform_fixed" | "dynamic"
      supplier_product_status:
        | "available"
        | "unavailable"
        | "discontinued"
        | "unknown"
      supplier_provider: "aliexpress" | "alibaba" | "custom"
      supplier_status: "pending" | "connected" | "disconnected" | "suspended"
      vendor_application_status:
        | "pending"
        | "approved"
        | "rejected"
        | "withdrawn"
      vendor_closure_request_status:
        | "pending"
        | "approved"
        | "rejected"
        | "withdrawn"
      vendor_earning_status:
        | "pending"
        | "available"
        | "reserved"
        | "paid"
        | "reversed"
      vendor_payout_status:
        | "pending"
        | "processing"
        | "succeeded"
        | "failed"
        | "cancelled"
      vendor_status: "active" | "suspended" | "closed"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      access_status: ["pending", "active", "suspended", "revoked"],
      account_status: [
        "active",
        "suspended",
        "deactivated",
        "pending_deletion",
      ],
      business_verification_status: [
        "not_submitted",
        "pending",
        "verified",
        "rejected",
      ],
      catalog_attribute_data_type: ["text", "number", "boolean"],
      catalog_attribute_usage: ["variant_option", "descriptive", "both"],
      category_status: ["active", "inactive"],
      checkout_status: [
        "active",
        "processing",
        "completed",
        "expired",
        "cancelled",
      ],
      digital_asset_type: [
        "pdf",
        "ebook",
        "image",
        "audio",
        "video",
        "archive",
        "other",
      ],
      fulfillment_source_type: ["platform", "vendor"],
      fulfillment_status: [
        "pending",
        "awaiting_supplier",
        "processing",
        "shipped",
        "delivered",
        "failed",
        "cancelled",
      ],
      inventory_adjustment_reason: [
        "restock",
        "sale",
        "return",
        "damage",
        "correction",
      ],
      inventory_location_ownership_type: ["platform", "vendor"],
      inventory_location_type: [
        "warehouse",
        "store",
        "fulfillment_center",
        "other",
      ],
      inventory_reservation_status: [
        "active",
        "committed",
        "released",
        "expired",
      ],
      inventory_tracking_mode: ["manual", "hybrid"],
      order_status: [
        "pending_payment",
        "paid",
        "processing",
        "partially_fulfilled",
        "fulfilled",
        "cancelled",
        "refunded",
        "partially_refunded",
      ],
      payment_provider: ["stripe", "paystack", "paypal"],
      payment_refund_status: ["pending", "succeeded", "failed"],
      payment_status: [
        "pending",
        "processing",
        "succeeded",
        "failed",
        "cancelled",
        "partially_refunded",
        "refunded",
      ],
      payout_account_status: [
        "pending_verification",
        "verified",
        "rejected",
        "disabled",
      ],
      platform_access_role: ["admin", "super_admin"],
      product_attribute_scope: ["product", "variant"],
      product_barcode_type: ["upc", "ean", "gtin"],
      product_dimension_unit: ["mm", "cm", "in"],
      product_discount_status: [
        "draft",
        "scheduled",
        "active",
        "expired",
        "disabled",
      ],
      product_discount_type: ["percentage", "fixed_amount"],
      product_ownership_type: ["platform", "vendor"],
      product_sku_source: ["generated", "manual"],
      product_status: [
        "draft",
        "pending_review",
        "active",
        "rejected",
        "archived",
      ],
      product_type: ["physical", "digital"],
      product_variant_status: [
        "active",
        "inactive",
        "discontinued",
        "archived",
      ],
      product_weight_unit: ["g", "kg", "oz", "lb"],
      return_reason: [
        "damaged",
        "defective",
        "wrong_item",
        "missing_parts",
        "not_as_described",
        "wrong_size",
        "changed_mind",
        "other",
      ],
      return_resolution: ["refund", "replacement", "no_refund"],
      return_status: [
        "requested",
        "approved",
        "rejected",
        "awaiting_shipment",
        "in_transit",
        "received",
        "inspecting",
        "completed",
        "cancelled",
      ],
      review_report_reason: [
        "spam",
        "abusive",
        "conflict_of_interest",
        "false_information",
        "other",
      ],
      review_report_status: ["pending", "resolved", "dismissed"],
      review_status: ["pending", "published", "rejected", "hidden"],
      shipment_status: [
        "pending",
        "label_created",
        "in_transit",
        "out_for_delivery",
        "delivered",
        "exception",
        "returned",
      ],
      shipping_rate_source: ["supplier", "platform_fixed", "dynamic"],
      supplier_product_status: [
        "available",
        "unavailable",
        "discontinued",
        "unknown",
      ],
      supplier_provider: ["aliexpress", "alibaba", "custom"],
      supplier_status: ["pending", "connected", "disconnected", "suspended"],
      vendor_application_status: [
        "pending",
        "approved",
        "rejected",
        "withdrawn",
      ],
      vendor_closure_request_status: [
        "pending",
        "approved",
        "rejected",
        "withdrawn",
      ],
      vendor_earning_status: [
        "pending",
        "available",
        "reserved",
        "paid",
        "reversed",
      ],
      vendor_payout_status: [
        "pending",
        "processing",
        "succeeded",
        "failed",
        "cancelled",
      ],
      vendor_status: ["active", "suspended", "closed"],
    },
  },
} as const
