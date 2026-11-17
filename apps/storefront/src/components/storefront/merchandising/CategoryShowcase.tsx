import Image from "next/image";
import Link from "next/link";

export type CategoryShowcaseItem = {
  id: string;
  name: string;
  slug: string;
  imageUrl: string;
  imageAlt: string;
  productCount?: number;
};

type CategoryShowcaseProps = {
  categories: CategoryShowcaseItem[];
  title?: string;
  eyebrow?: string;
  description?: string;
};

export function CategoryShowcase({
  categories,
  title = "Explore by category.",
  eyebrow = "Find your next favourite",
  description = "Discover thoughtfully selected pieces across the things you love.",
}: CategoryShowcaseProps) {
  if (!categories.length) return null;

  return (
    <section className="space-y-8">
      <div className="max-w-xl">
        <p className="mb-3 font-mono text-[10px] uppercase tracking-[0.2em] text-text-muted">
          {eyebrow}
        </p>
        <h2 className="font-heading text-3xl tracking-tight text-foreground sm:text-4xl">
          {title}
        </h2>
        <p className="mt-3 text-sm leading-6 text-text-muted">{description}</p>
      </div>

      <div className="grid grid-cols-2 gap-3 sm:gap-5 lg:grid-cols-4">
        {categories.map((category, index) => {
          const isHero = index === 0;

          return (
            <Link
              key={category.id}
              href={`/categories/${category.slug}`}
              className={`group relative isolate block overflow-hidden bg-surface focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-foreground ${
                isHero
                  ? "col-span-2 aspect-4/5 sm:aspect-5/4 lg:row-span-2 lg:aspect-auto lg:min-h-112"
                  : "col-span-1 aspect-4/5"
              }`}
            >
              <Image
                src={category.imageUrl}
                alt={category.imageAlt}
                fill
                priority={isHero}
                sizes={
                  isHero
                    ? "(max-width: 1024px) 100vw, 50vw"
                    : "(max-width: 1024px) 50vw, 25vw"
                }
                className="object-cover transition-transform duration-700 ease-out group-hover:scale-105 group-focus-visible:scale-105 motion-reduce:transition-none motion-reduce:group-hover:scale-100"
              />

              <div
                className={`absolute inset-0 bg-linear-to-t via-transparent to-transparent ${
                  isHero
                    ? "from-black/70 via-black/10"
                    : "from-black/60 via-black/5"
                }`}
              />

              <div className="absolute inset-x-0 bottom-0 p-4 text-white sm:p-6">
                <h3
                  className={`font-heading leading-tight ${
                    isHero ? "text-2xl sm:text-4xl" : "text-lg sm:text-2xl"
                  }`}
                >
                  {category.name}
                </h3>

                {category.productCount !== undefined && (
                  <p className="mt-1 text-xs text-white/75">
                    {category.productCount}{" "}
                    {category.productCount === 1 ? "product" : "products"}
                  </p>
                )}

                <span className="mt-3 inline-flex items-center gap-2 text-xs font-medium transition-all duration-300 lg:translate-y-1 lg:opacity-0 lg:group-hover:translate-y-0 lg:group-hover:opacity-100 lg:group-focus-visible:translate-y-0 lg:group-focus-visible:opacity-100">
                  Explore category <span aria-hidden="true">↗</span>
                </span>
              </div>
            </Link>
          );
        })}
      </div>
    </section>
  );
}
