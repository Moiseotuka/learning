"use client";

import type { User } from "@supabase/supabase-js";
import { LayoutDashboardIcon, LogOutIcon } from "lucide-react";
import Link from "next/link";
import { useEffect, useState } from "react";

import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { links } from "@/config/site";
import { messages } from "@/i18n";
import { signOut } from "@/lib/actions/auth";
import { createBrowserSupabase } from "@/lib/supabase/client";
import { isSupabaseConfigured } from "@/lib/supabase/config";

const t = messages;

type Account = { name: string; email: string } | null;

function toAccount(user: User | null): Account {
  if (!user) return null;
  const metadataName =
    typeof user.user_metadata?.full_name === "string"
      ? user.user_metadata.full_name.trim()
      : "";
  const email = user.email ?? "";
  return { name: metadataName || email.split("@")[0] || "Compte", email };
}

function SignOutControl({
  className,
  labelClassName,
}: {
  className?: string;
  labelClassName?: string;
}) {
  const [open, setOpen] = useState(false);

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button
          type="button"
          variant="ghost"
          className={className}
          title={t.auth.signOut}
          aria-label={t.auth.signOut}
        >
          <LogOutIcon aria-hidden />
          <span className={labelClassName}>{t.auth.signOut}</span>
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{t.auth.signOutTitle}</DialogTitle>
          <DialogDescription>{t.auth.signOutDescription}</DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button type="button" variant="outline" onClick={() => setOpen(false)}>
            {t.auth.signOutCancel}
          </Button>
          <form action={signOut} className="w-full sm:w-auto">
            <Button type="submit" className="w-full">
              {t.auth.signOutConfirm}
            </Button>
          </form>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

export function AuthActions({
  variant = "bar",
  onNavigate,
}: {
  variant?: "bar" | "sheet";
  onNavigate?: () => void;
}) {
  const [checked, setChecked] = useState(false);
  const [account, setAccount] = useState<Account>(null);
  const [isAdmin, setIsAdmin] = useState(false);

  useEffect(() => {
    const supabase = createBrowserSupabase();
    if (!supabase) return;

    let active = true;
    const apply = (user: User | null) => {
      if (!active) return;
      setAccount(toAccount(user));
      setChecked(true);
      if (user) {
        void Promise.resolve(
          supabase.from("profiles").select("role").eq("id", user.id).maybeSingle(),
        )
          .then(({ data }) => {
            if (active) setIsAdmin(data?.role === "admin");
          })
          .catch(() => undefined);
      } else if (active) {
        setIsAdmin(false);
      }
    };

    supabase.auth
      .getUser()
      .then(({ data }) => apply(data.user))
      .catch(() => {
        if (active) setChecked(true);
      });

    const { data } = supabase.auth.onAuthStateChange((_event, session) =>
      apply(session?.user ?? null),
    );

    return () => {
      active = false;
      data.subscription.unsubscribe();
    };
  }, []);

  const ready = !isSupabaseConfigured || checked;

  if (!ready) return null;

  if (!account) {
    if (variant === "sheet") {
      return (
        <>
          <Button asChild variant="outline" className="h-10">
            <Link href={links.login} onClick={onNavigate}>
              {t.nav.login}
            </Link>
          </Button>
          <Button asChild className="h-10">
            <Link href={links.signup} onClick={onNavigate}>
              {t.nav.signup}
            </Link>
          </Button>
        </>
      );
    }

    return (
      <>
        <Button
          asChild
          variant="ghost"
          className="hidden text-muted-foreground hover:text-foreground sm:inline-flex"
        >
          <Link href={links.login}>{t.nav.login}</Link>
        </Button>
        <Button asChild className="h-9 px-4">
          <Link href={links.signup}>{t.nav.signup}</Link>
        </Button>
      </>
    );
  }

  const initial = account.name.trim().charAt(0).toUpperCase() || "?";

  if (variant === "sheet") {
    return (
      <div className="flex flex-col gap-2">
        <p className="px-1 text-xs text-muted-foreground">
          {t.auth.signedInAs} {account.email}
        </p>
        <Button asChild variant="outline" className="h-10">
          <Link href={links.dashboard} onClick={onNavigate}>
            <LayoutDashboardIcon aria-hidden />
            {t.auth.mySpace}
          </Link>
        </Button>
        {isAdmin ? (
          <Button asChild variant="outline" className="h-10">
            <Link href={links.admin} onClick={onNavigate}>
              <LayoutDashboardIcon aria-hidden />
              {t.admin.title}
            </Link>
          </Button>
        ) : null}
        <SignOutControl className="h-10 w-full" labelClassName="inline" />
      </div>
    );
  }

  return (
    <>
      {isAdmin ? (
        <Button
          asChild
          variant="ghost"
          className="hidden text-muted-foreground hover:text-foreground sm:inline-flex"
        >
          <Link
            href={links.admin}
            title={t.admin.title}
            aria-label={t.admin.title}
          >
            <LayoutDashboardIcon aria-hidden />
          </Link>
        </Button>
      ) : null}
      <Button
        asChild
        variant="ghost"
        className="gap-2 px-2 text-muted-foreground hover:text-foreground"
      >
        <Link
          href={links.dashboard}
          title={`${t.auth.signedInAs} ${account.email}`}
          aria-label={t.auth.mySpace}
        >
          <Avatar size="sm">
            <AvatarFallback>{initial}</AvatarFallback>
          </Avatar>
          <span className="hidden max-w-28 truncate sm:inline">{account.name}</span>
        </Link>
      </Button>
      <SignOutControl
        className="text-muted-foreground hover:text-foreground"
        labelClassName="hidden md:inline"
      />
    </>
  );
}
