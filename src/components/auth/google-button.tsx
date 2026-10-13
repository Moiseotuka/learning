"use client";

import { Loader2Icon } from "lucide-react";
import { useState } from "react";

import { messages } from "@/i18n";
import { loginWithGoogle } from "@/lib/actions/auth";

function GoogleMark() {
  return (
    <svg viewBox="0 0 18 18" className="size-[18px]" aria-hidden focusable="false">
      <path
        fill="#4285F4"
        d="M17.64 9.2c0-.64-.06-1.25-.16-1.84H9v3.48h4.84a4.14 4.14 0 0 1-1.8 2.72v2.26h2.92c1.7-1.57 2.68-3.88 2.68-6.62z"
      />
      <path
        fill="#34A853"
        d="M9 18c2.43 0 4.47-.8 5.96-2.18l-2.92-2.26c-.8.54-1.84.86-3.04.86-2.34 0-4.32-1.58-5.03-3.7H.96v2.33A9 9 0 0 0 9 18z"
      />
      <path
        fill="#FBBC05"
        d="M3.97 10.72a5.4 5.4 0 0 1 0-3.44V4.95H.96a9 9 0 0 0 0 8.1l3.01-2.33z"
      />
      <path
        fill="#EA4335"
        d="M9 3.58c1.32 0 2.5.45 3.44 1.35l2.58-2.58C13.46.9 11.43 0 9 0A9 9 0 0 0 .96 4.95l3.01 2.33C4.68 5.16 6.66 3.58 9 3.58z"
      />
    </svg>
  );
}

/**
 * Bouton Google à sa charte : fond blanc, liseré gris, lettres sombres. Il
 * volontairement ne passe pas par `Button` — les variantes du thème peignent un
 * fond translucent qui, sur la carte déjà sombre, rendait l'option illisible.
 * Le blanc franc reste au contraire le contraste maximal dans les deux thèmes.
 */
export function GoogleButton({ next, label }: { next?: string; label: string }) {
  const [pending, setPending] = useState(false);

  const handleSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    if (pending) {
      event.preventDefault();
      return;
    }
    setPending(true);
  };

  return (
    <form action={loginWithGoogle} onSubmit={handleSubmit}>
      <input type="hidden" name="next" value={next ?? ""} />
      <button
        type="submit"
        disabled={pending}
        className="inline-flex h-12 w-full items-center justify-center gap-3 rounded-xl border border-[#d2d7de] bg-white px-4 text-sm font-semibold text-[#1d1f21] shadow-sm outline-none transition-colors hover:border-[#b7bec8] hover:bg-[#f4f6f8] focus-visible:ring-3 focus-visible:ring-ring/60 active:translate-y-px disabled:pointer-events-none disabled:opacity-60"
      >
        {pending ? (
          <Loader2Icon className="size-[18px] animate-spin" aria-hidden />
        ) : (
          <GoogleMark />
        )}
        {label}
      </button>
    </form>
  );
}

export function AuthDivider({ label = messages.auth.orEmail }) {
  return (
    <div className="relative my-5 text-center">
      <span className="absolute inset-x-0 top-1/2 border-t border-hairline" aria-hidden />
      <span className="relative bg-card px-3 text-xs text-muted-foreground">{label}</span>
    </div>
  );
}
