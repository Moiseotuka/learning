import { cn } from "cn";

export function ProgressBar({
  percent,
  className,
}: {
  percent: number;
  className?: string;
}) {
  const value = Math.max(0, Math.min(100, percent));

  return (
    <div
      role="progressbar"
      aria-valuenow={value}
      aria-valuemin={0}
      aria-valuemax={100}
      className={cn(
        "h-2 w-full overflow-hidden rounded-full bg-muted",
        className,
      )}
    >
      <div
        className="h-full rounded-full bg-electric transition-all duration-500"
        style={{ width: `${value}%` }}
      />
    </div>
  );
}
