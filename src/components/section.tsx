import { Reveal } from "@/components/reveal";
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

/**
 * Titre de section animé : les trois lignes entrent en cascade, ce qui donne du
 * rythme à tout le landing sans qu'il faille emballer chaque section à la main.
 */
export function SectionHeading({
  eyebrow,
  title,
  description,
  align = "center",
  className,
  variant = "up",
}: {
  eyebrow?: string;
  title: string;
  description?: string;
  align?: "center" | "left";
  className?: string;
  variant?: "up" | "blur" | "left" | "right";
}) {
  const centre = align === "center";
  return (
    <div
      className={cn(
        "mb-10 max-w-3xl sm:mb-12",
        centre ? "mx-auto text-center" : "text-start",
        className,
      )}
    >
      {eyebrow && (
        <Reveal variant={variant === "up" ? "blur" : variant}>
          <p className="mb-3 text-xs font-semibold tracking-[0.18em] text-electric uppercase">
            {eyebrow}
          </p>
        </Reveal>
      )}
      <Reveal variant={variant} delay={90}>
        <h2 className="text-balance-tight text-2xl font-semibold tracking-tight text-balance sm:text-3xl lg:text-4xl">
          {title}
        </h2>
      </Reveal>
      <Reveal variant="up" delay={170} as="span" className="block">
        <span
          aria-hidden
          className={cn(
            "mt-4 block h-0.5 w-14 rounded-full bg-gradient-to-r from-electric to-vivid",
            centre && "mx-auto",
          )}
        />
      </Reveal>
      {description && (
        <Reveal variant="up" delay={230}>
          <p className="mt-4 text-pretty text-sm leading-relaxed text-muted-foreground sm:text-base">
            {description}
          </p>
        </Reveal>
      )}
    </div>
  );
}
