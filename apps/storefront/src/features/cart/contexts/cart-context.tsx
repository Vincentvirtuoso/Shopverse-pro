"use client";

import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useReducer,
  type ReactNode,
} from "react";

export interface CartItem {
  productId: string;
  variantId?: string | null;
  slug: string;
  name: string;
  imageUrl: string;
  vendorId: string;
  vendorName: string;
  unitAmountMinor: number;
  currency: string;
  quantity: number;
}

interface CartState {
  items: CartItem[];
}

type CartAction =
  | { type: "ADD_ITEM"; item: CartItem }
  | {
      type: "SET_QUANTITY";
      productId: string;
      variantId?: string | null;
      quantity: number;
    }
  | {
      type: "REMOVE_ITEM";
      productId: string;
      variantId?: string | null;
    }
  | { type: "CLEAR_CART" };

interface CartContextValue {
  items: CartItem[];
  itemCount: number;
  subtotalMinor: number;
  addItem: (item: CartItem) => void;
  setQuantity: (
    productId: string,
    variantId: string | null | undefined,
    quantity: number,
  ) => void;
  removeItem: (productId: string, variantId?: string | null) => void;
  clearCart: () => void;
}

const initialState: CartState = {
  items: [],
};

function isSameItem(
  item: CartItem,
  productId: string,
  variantId?: string | null,
) {
  return (
    item.productId === productId &&
    (item.variantId ?? null) === (variantId ?? null)
  );
}

function cartReducer(state: CartState, action: CartAction): CartState {
  switch (action.type) {
    case "ADD_ITEM": {
      const incoming = action.item;

      const existing = state.items.find((item) =>
        isSameItem(item, incoming.productId, incoming.variantId),
      );

      if (!existing) {
        return {
          ...state,
          items: [...state.items, incoming],
        };
      }

      return {
        ...state,
        items: state.items.map((item) =>
          isSameItem(item, incoming.productId, incoming.variantId)
            ? {
                ...item,
                quantity: item.quantity + incoming.quantity,
                name: incoming.name,
                imageUrl: incoming.imageUrl,
                unitAmountMinor: incoming.unitAmountMinor,
                currency: incoming.currency,
              }
            : item,
        ),
      };
    }

    case "SET_QUANTITY": {
      if (action.quantity <= 0) {
        return {
          ...state,
          items: state.items.filter(
            (item) => !isSameItem(item, action.productId, action.variantId),
          ),
        };
      }

      return {
        ...state,
        items: state.items.map((item) =>
          isSameItem(item, action.productId, action.variantId)
            ? { ...item, quantity: action.quantity }
            : item,
        ),
      };
    }

    case "REMOVE_ITEM":
      return {
        ...state,
        items: state.items.filter(
          (item) => !isSameItem(item, action.productId, action.variantId),
        ),
      };

    case "CLEAR_CART":
      return initialState;

    default:
      return state;
  }
}

const CartContext = createContext<CartContextValue | null>(null);

export function CartProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(cartReducer, initialState);

  const addItem = useCallback((item: CartItem) => {
    dispatch({ type: "ADD_ITEM", item });
  }, []);

  const setQuantity = useCallback(
    (
      productId: string,
      variantId: string | null | undefined,
      quantity: number,
    ) => {
      dispatch({
        type: "SET_QUANTITY",
        productId,
        variantId,
        quantity,
      });
    },
    [],
  );

  const removeItem = useCallback(
    (productId: string, variantId?: string | null) => {
      dispatch({ type: "REMOVE_ITEM", productId, variantId });
    },
    [],
  );

  const clearCart = useCallback(() => {
    dispatch({ type: "CLEAR_CART" });
  }, []);

  const value = useMemo<CartContextValue>(() => {
    const itemCount = state.items.reduce(
      (total, item) => total + item.quantity,
      0,
    );

    const subtotalMinor = state.items.reduce(
      (total, item) => total + item.unitAmountMinor * item.quantity,
      0,
    );

    return {
      items: state.items,
      itemCount,
      subtotalMinor,
      addItem,
      setQuantity,
      removeItem,
      clearCart,
    };
  }, [state.items, addItem, setQuantity, removeItem, clearCart]);

  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}

export function useCart() {
  const context = useContext(CartContext);

  if (!context) {
    throw new Error("useCart must be used within CartProvider");
  }

  return context;
}
