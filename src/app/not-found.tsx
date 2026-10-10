import Link from "next/link";
import { ArrowLeftIcon } from "lucide-react";

import { Logo } from "@/components/logo";
import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";

export default function NotFound() {
  return (
    <div className="relative flex flex-1 items-center justify-center overflow-hidden px-4 py-24">
      <div className="relative max-w-md text-center">
        <div className="flex justify-center">
          <Logo />
        </div>
        <p className="mt-8 text-5xl font-semibold text-electric">404</p>
        <h1 className="mt-3 text-2xl font-semibold tracking-tight">
          {messages.common.notFoundTitle}
        </h1>
        <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
          {messages.common.notFoundText}
        </p>
        <Button asChild className="mt-8 h-11 px-5">
          <Link href="/">
            <ArrowLeftIcon className="size-4" aria-hidden />
            {messages.auth.backHome}
          </Link>
        </Button>
      </div>
    </div>
  );
}
