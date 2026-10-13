"use client";

import { CheckIcon, CopyIcon } from "lucide-react";
import { useState } from "react";

import { Button } from "@/components/ui/button";

/**
 * Copie du code de classe. `navigator.clipboard` exige un contexte sécurisé ;
 * en HTTP local l'API est absente et le code reste lisible à l'écran, donc on
 * se contente d'afficher la confirmation quand elle fonctionne.
 */
export function CopyCode({
  code,
  label,
  copied,
}: {
  code: string;
  label: string;
  copied: string;
}) {
  const [done, setDone] = useState(false);

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(code);
      setDone(true);
      window.setTimeout(() => setDone(false), 2000);
    } catch {
      /* le formateur dicte le code affiché : rien à signaler */
    }
  };

  return (
    <Button
      type="button"
      variant="ghost"
      size="sm"
      className="h-8 px-2.5 text-xs"
      onClick={copy}
    >
      {done ? (
        <CheckIcon className="text-emerald-500" aria-hidden />
      ) : (
        <CopyIcon aria-hidden />
      )}
      {done ? copied : label}
    </Button>
  );
}
