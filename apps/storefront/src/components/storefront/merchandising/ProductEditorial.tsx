import Image from "next/image";
import Link from "next/link";

type ProductEditorialProps = {
  eyebrow?: string;
  title: string;
  description: string;
  imageUrl: string;
  imageAlt: string;
  href: string;
  linkLabel?: string;
  imagePosition?: "left" | "right";
  imageAspect?: "portrait" | "landscape";
};

export function ProductEditorial({
  eyebrow,
  title,
  description,
  imageUrl,
  imageAlt,
  href,
  linkLabel = "Explore collection",
  imagePosition = "left",
  imageAspect = "portrait",
}: ProductEditorialProps) {
  const image = (
    <div
      className={`relative overflow-hidden bg-surface ${
        imageAspect === "portrait" ? "aspect-4/5" : "aspect-5/4"
      }`}
    >
      <Image
        src={imageUrl}
        alt={imageAlt}
        fill
        sizes="(max-width: 768px) 100vw, 50vw"
        className="object-cover transition-transform duration-700 hover:scale-[1.03]"
      />
    </div>
  );

  const content = (
    <div className="flex min-h-full flex-col justify-center py-8 md:px-10 lg:px-16">
      {eyebrow && (
        <span className="mb-5 font-mono text-[10px] uppercase tracking-[0.2em] text-text-muted">
          {eyebrow}
        </span>
      )}

      <h2 className="max-w-xl font-heading text-4xl leading-[1.08] tracking-tight text-foreground sm:text-5xl lg:text-6xl">
        {title}
      </h2>

      <p className="mt-6 max-w-md text-sm leading-7 text-text-muted sm:text-base">
        {description}
      </p>

      <Link
        href={href}
        className="mt-8 inline-flex w-fit items-center gap-3 border-b border-foreground pb-2 text-sm font-medium text-foreground transition-opacity hover:opacity-60"
      >
        {linkLabel}
        <span aria-hidden="true">↗</span>
      </Link>
    </div>
  );

  return (
    <section className="grid grid-cols-1 items-center gap-8 md:grid-cols-2 md:gap-0">
      {imagePosition === "left" ? (
        <>
          {image}
          {content}
        </>
      ) : (
        <>
          {content}
          {image}
        </>
      )}
    </section>
  );
}
