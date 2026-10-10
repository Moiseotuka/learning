import { cn } from "@/lib/utils";

export function Section({
  id,
  children,
  className,
  containerClassName,
}: {
  id?: string;
  children: React.ReactNode;
  className?: string;
  containerClassName?: string;
}) {
  return (
    <section id={id} className={cn("scroll-mt-24 py-16 sm:py-20 lg:py-24", className)}>
      <div className={cn("mx-auto w-full max-w-6xl px-4 sm:px-6", containerClassName)}>
        {children}
      </div>
    </section>
  );
}

export function SectionHeading({
  eyebrow,
  title,
  description,
  align = "center",
  className,
}: {
  eyebrow?: string;
  title: string;
  description?: string;
  align?: "center" | "left";
  className?: string;
}) {
  return (
    <div
      className={cn(
        "mb-10 max-w-3xl sm:mb-12",
        align === "center" ? "mx-auto text-center" : "text-start",
        className,
      )}
    >
      {eyebrow && (
        <p className="mb-3 text-xs font-semibold tracking-[0.18em] text-electric uppercase">
          {eyebrow}
        </p>
      )}
      <h2 className="text-balance-tight text-2xl font-semibold tracking-tight text-balance sm:text-3xl lg:text-4xl">
        {title}
      </h2>
      {description && (
        <p className="mt-4 text-pretty text-sm leading-relaxed text-muted-foreground sm:text-base">
          {description}
        </p>
      )}
    </div>
  );
}
