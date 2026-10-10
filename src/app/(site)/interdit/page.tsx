import { ArrowLeftIcon, ShieldAlertIcon } from "lucide-react";
import Link from "next/link";

import { Logo } from "@/components/logo";
import { Button } from "@/components/ui/button";
import { links } from "@/config/site";
import { messages } from "@/i18n";

const t = messages.admin;

export default function ForbiddenPage() {
  return (
    <div className="relative flex flex-1 items-center justify-center overflow-hidden px-4 py-24">
      <div className="relative max-w-md text-center">
        <div className="flex justify-center">
          <Logo />
        </div>
        <span className="mt-8 grid size-14 place-items-center rounded-2xl bg-destructive/10 text-destructive">
          <ShieldAlertIcon className="size-7" aria-hidden />
        </span>
        <h1 className="mt-4 text-2xl font-semibold tracking-tight">
          {t.forbiddenTitle}
        </h1>
        <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
          {t.forbiddenText}
        </p>
        <Button asChild className="mt-8 h-11 px-5">
          <Link href={links.home}>
            <ArrowLeftIcon className="size-4" aria-hidden />
            {t.forbiddenBack}
          </Link>
        </Button>
      </div>
    </div>
  );
}
