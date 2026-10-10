"use client";

import { useTheme } from "next-themes";
import { MoonIcon, SunIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import { useHydrated } from "@/hooks/use-hydrated";
import { messages } from "@/i18n";

export function ThemeToggle() {
  const { resolvedTheme, setTheme } = useTheme();
  const hydrated = useHydrated();

  const isDark = hydrated ? resolvedTheme !== "light" : true;

  return (
    <Button
      variant="ghost"
      size="icon-sm"
      aria-label={messages.nav.theme}
      className="text-muted-foreground hover:text-foreground"
      onClick={() => setTheme(isDark ? "light" : "dark")}
    >
      {isDark ? (
        <SunIcon className="size-4" aria-hidden />
      ) : (
        <MoonIcon className="size-4" aria-hidden />
      )}
    </Button>
  );
}
