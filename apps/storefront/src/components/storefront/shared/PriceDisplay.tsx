type PriceDisplayProps = {
  amount: number;
  originalAmount?: number;
  currency?: string;
  size?: "sm" | "md" | "lg";
  className?: string;
};

const currencyFormatter = new Intl.NumberFormat("en-NG", {
  style: "currency",
  currency: "NGN",
  maximumFractionDigits: 0,
});

export function PriceDisplay({
  amount,
  originalAmount,
  currency = "NGN",
  size = "md",
  className = "",
}: PriceDisplayProps) {
  const formatter =
    currency === "NGN"
      ? currencyFormatter
      : new Intl.NumberFormat("en", {
          style: "currency",
          currency,
          maximumFractionDigits: 2,
        });

  const sizeClasses = {
    sm: "text-xs",
    md: "text-sm",
    lg: "text-lg",
  };

  return (
    <div className={`flex flex-wrap items-center gap-2 ${className}`}>
      <span className={`font-semibold text-foreground ${sizeClasses[size]}`}>
        {formatter.format(amount)}
      </span>

      {originalAmount !== undefined && originalAmount > amount && (
        <span className="text-xs text-text-muted line-through">
          {formatter.format(originalAmount)}
        </span>
      )}
    </div>
  );
}
