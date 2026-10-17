import Image from "next/image";

import { cn } from "@/lib/utils";

const HAUTEURS = { petite: 24, moyenne: 34, grande: 42 } as const;

/**
 * Marque easyTech, en vraies images PNG déposées dans `public/` : l'icône seule quand la place
 * manque (rail d'administration), le logotype complet ailleurs. Le logotype est fourni en deux
 * couleurs parce que le thème clair et le thème sombre ne lisent pas le même fichier ; le texte
 * reste accessible aux lecteurs d'écran même si l'image échoue.
 */
export function Logo({
  className,
  compact = false,
  size = "moyenne",
}: {
  className?: string;
  compact?: boolean;
  size?: keyof typeof HAUTEURS;
}) {
  const hauteur = HAUTEURS[size];

  if (compact) {
    return (
      <Image
        src="/easytech-logo-256.png"
        alt="easyTech"
        width={256}
        height={256}
        priority
        className={cn("size-9 shrink-0 rounded-lg", className)}
      />
    );
  }

  return (
    <span
      className={cn("inline-flex shrink-0 items-center", className)}
      style={{ height: hauteur }}
    >
      <Image
        src="/easytech-logo-texte-fonce.png"
        alt=""
        width={960}
        height={256}
        priority
        style={{ height: hauteur, width: "auto" }}
        className="dark:hidden"
      />
      <Image
        src="/easytech-logo-texte-blanc.png"
        alt=""
        width={960}
        height={256}
        style={{ height: hauteur, width: "auto" }}
        className="hidden dark:block"
      />
      <span className="sr-only">easyTech</span>
    </span>
  );
}
