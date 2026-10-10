import Link from "next/link";
import { ArrowLeftIcon } from "lucide-react";

import { Logo } from "@/components/logo";
import { Button } from "@/components/ui/button";
import { links } from "@/config/site";
import { messages } from "@/i18n";

/**
 * Page d'attente utilisée pour les routes qui seront câblées
 * à une étape ultérieure (auth, vérification, back-office).
 */
export function PlaceholderPage({
  title,
  note,
}: {
  title: string;
  note?: string;
}) {
  return (
    <div className="relative flex min-h-[65vh] items-center justify-center overflow-hidden px-4 py-20">
      <div className="relative w-full max-w-lg rounded-2xl border border-hairline bg-card p-8 text-center">
        <div className="flex justify-center">
          <Logo />
        </div>

        <h1 className="mt-6 text-2xl font-semibold tracking-tight">{title}</h1>
        <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
          {note}
        </p>

        <Button asChild variant="outline" className="mt-7 h-11 border-hairline px-5">
          <Link href={links.home}>
            <ArrowLeftIcon className="size-4" aria-hidden />
            {messages.auth.backHome}
          </Link>
        </Button>
      </div>
    </div>
  );
}
