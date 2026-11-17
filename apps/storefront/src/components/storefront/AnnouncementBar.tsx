"use client";

import { useStorefrontChrome } from "./StorefrontChromeContext";
import { useMeasuredHeight } from "./useMeasuredHeight";

export function AnnouncementBar() {
  const { setAnnouncementHeight } = useStorefrontChrome();
  const ref = useMeasuredHeight(setAnnouncementHeight);

  return (
    <div
      ref={ref as React.RefObject<HTMLDivElement>}
      className="bg-neutral-950 px-4 py-2 text-center text-xs text-white"
    >
      Discover something good. Shop from independent vendors.
    </div>
  );
}
