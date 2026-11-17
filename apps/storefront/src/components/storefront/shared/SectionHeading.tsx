import Link from "next/link";

type SectionHeadingProps = {
  eyebrow?: string;
  title: string;
  description?: string;
  href?: string;
  linkLabel?: string;
};

export function SectionHeading({
  eyebrow,
  title,
  description,
  href,
  linkLabel = "View all",
}: SectionHeadingProps) {
  return (
    <div className="mb-7 flex flex-wrap items-end justify-between gap-4 sm:mb-9">
      <div className="max-w-xl">
        {eyebrow && (
          <p className="mb-2 text-[10px] font-medium uppercase tracking-[0.2em] text-brand">
            {eyebrow}
          </p>
        )}

        <h2 className="font-heading text-3xl leading-tight text-foreground sm:text-4xl">
          {title}
        </h2>

        {description && (
          <p className="mt-2 text-sm leading-6 text-text-muted">
            {description}
          </p>
        )}
      </div>

      {href && (
        <Link
          href={href}
          className="shrink-0 border-b border-foreground pb-1 text-xs font-medium text-foreground transition-colors hover:border-brand hover:text-brand"
        >
          {linkLabel}
        </Link>
      )}
    </div>
  );
}
