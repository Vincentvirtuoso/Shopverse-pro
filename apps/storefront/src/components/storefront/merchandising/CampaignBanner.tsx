import Image from "next/image";
import Link from "next/link";

type CampaignBannerProps = {
  eyebrow?: string;
  title: string;
  description?: string;
  imageUrl: string;
  imageAlt: string;
  href: string;
  linkLabel?: string;
  theme?: "dark" | "light";
  imagePosition?: "left" | "right";
};

export function CampaignBanner({
  eyebrow,
  title,
  description,
  imageUrl,
  imageAlt,
  href,
  linkLabel = "Discover more",
  theme = "dark",
  imagePosition = "right",
}: CampaignBannerProps) {
  const isDark = theme === "dark";

  return (
    <section
      className={`relative isolate grid min-h-90 overflow-hidden md:min-h-105 md:grid-cols-2 ${
        isDark ? "bg-[#24231F] text-white" : "bg-[#EDE9E1] text-[#24231F]"
      }`}
    >
      <div
        className={`relative z-10 flex flex-col justify-center px-7 py-12 sm:px-12 lg:px-16 ${
          imagePosition === "left" ? "md:order-2" : ""
        }`}
      >
        {eyebrow && (
          <p
            className={`mb-5 font-mono text-[10px] uppercase tracking-[0.2em] ${
              isDark ? "text-white/60" : "text-black/50"
            }`}
          >
            {eyebrow}
          </p>
        )}

        <h2 className="max-w-lg font-heading text-4xl leading-[1.08] tracking-tight sm:text-5xl lg:text-6xl">
          {title}
        </h2>

        {description && (
          <p
            className={`mt-5 max-w-md text-sm leading-7 ${
              isDark ? "text-white/70" : "text-black/65"
            }`}
          >
            {description}
          </p>
        )}

        <Link
          href={href}
          className={`mt-8 inline-flex w-fit items-center gap-3 border-b pb-2 text-sm font-medium transition-opacity hover:opacity-60 ${
            isDark ? "border-white text-white" : "border-black text-black"
          }`}
        >
          {linkLabel}
          <span aria-hidden="true">↗</span>
        </Link>
      </div>

      <div
        className={`relative min-h-65 ${
          imagePosition === "left" ? "md:order-1" : ""
        }`}
      >
        <Image
          src={imageUrl}
          alt={imageAlt}
          fill
          sizes="(max-width: 768px) 100vw, 50vw"
          className="object-cover"
        />
      </div>
    </section>
  );
}
