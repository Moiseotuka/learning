"use client";

import { useEffect, useRef, useState, type ElementType, type ReactNode } from "react";

type RevealProps = {
  children: ReactNode;
  className?: string;
  delay?: number;
  as?: ElementType;
  variant?: "up" | "scale" | "left" | "right" | "zoom" | "blur";
};

const CLASSE_VARIANTE: Record<NonNullable<RevealProps["variant"]>, string> = {
  up: "reveal",
  scale: "reveal-scale",
  left: "reveal-left",
  right: "reveal-right",
  zoom: "reveal-zoom",
  blur: "reveal-blur",
};

/**
 * Apparition discrète au scroll (une seule fois, hors `prefers-reduced-motion`).
 */
export function Reveal({
  children,
  className = "",
  delay = 0,
  as: Tag = "div",
  variant = "up",
}: RevealProps) {
  const ref = useRef<HTMLElement | null>(null);
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const node = ref.current;
    if (!node) return;

    if (typeof IntersectionObserver === "undefined") {
      // Hors navigateur : visible immédiatement (hors du corps de l'effet).
      const fallback = window.setTimeout(() => setVisible(true), 0);
      return () => window.clearTimeout(fallback);
    }

    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          // `top < 0` : la section a déjà été dépassée d'un seul bond (lien d'ancre,
          // scroll rapide, fin de page). Sans cela, son contenu resterait invisible
          // à 0 % d'opacité — une page blanche pour celui qui a cliqué sur un titre.
          if (entry.isIntersecting || entry.boundingClientRect.top < 0) {
            setVisible(true);
            observer.disconnect();
          }
        }
      },
      { threshold: 0.15, rootMargin: "0px 0px -60px 0px" },
    );

    observer.observe(node);
    return () => observer.disconnect();
  }, []);

  const variantClass = CLASSE_VARIANTE[variant];

  return (
    <Tag
      ref={ref}
      className={`${variantClass} ${visible ? "is-visible" : ""} ${className}`}
      style={{ ["--reveal-delay" as string]: `${delay}ms` }}
    >
      {children}
    </Tag>
  );
}
