"use client";

import { useLayoutEffect, useRef } from "react";

export function useMeasuredHeight(onHeightChange: (height: number) => void) {
  const elementRef = useRef<HTMLElement>(null);

  useLayoutEffect(() => {
    const element = elementRef.current;
    if (!element) return;

    const observer = new ResizeObserver(([entry]) => {
      if (entry) {
        onHeightChange(entry.contentRect.height);
      }
    });

    observer.observe(element);

    onHeightChange(element.getBoundingClientRect().height);

    return () => observer.disconnect();
  }, [onHeightChange]);

  return elementRef;
}
