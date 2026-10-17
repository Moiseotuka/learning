import type { Metadata } from "next";
import { BellOffIcon, CheckCircle2Icon, ShieldQuestionIcon } from "lucide-react";

import { ConsentForm } from "@/components/marketing/consent-form";
import { messages } from "@/i18n";
import { consentFor } from "@/lib/marketing/queue";

const t = messages.relances;

/** Page utilitaire derrière un jeton : rien ici n'a à se retrouver dans un index. */
export function generateMetadata(): Metadata {
  return {
    title: t.title,
    description: t.description,
    robots: { index: false, follow: true },
  };
}

export default async function UnsubscribePage(props: PageProps<"/desinscription">) {
  const searchParams = await props.searchParams;
  const token =
    typeof searchParams.token === "string" ? searchParams.token.trim() : "";

  const consent = token ? await consentFor(token) : null;

  return (
    <div className="mx-auto w-full max-w-xl px-4 py-12 sm:px-6 lg:py-16">
      <header className="text-center">
        <p className="text-xs font-semibold uppercase tracking-wider text-electric">
          {t.eyebrow}
        </p>
        <h1 className="mt-2 text-3xl font-semibold tracking-tight text-foreground">
          {t.title}
        </h1>
        <p className="mx-auto mt-3 max-w-[60ch] text-sm leading-relaxed text-muted-foreground">
          {t.intro}
        </p>
      </header>

      {consent ? (
        <>
          <section className="mt-8 rounded-2xl border border-hairline bg-card p-5 sm:p-6">
            <dl className="space-y-4 text-sm">
              <div>
                <dt className="text-xs uppercase tracking-wider text-muted-foreground">
                  {t.addressLabel}
                </dt>
                <dd className="mt-0.5 font-semibold text-foreground">
                  {consent.email}
                </dd>
              </div>
              <div>
                <dt className="text-xs uppercase tracking-wider text-muted-foreground">
                  {t.stateLabel}
                </dt>
                <dd
                  className={
                    consent.optedOut
                      ? "mt-1 flex items-center gap-2 font-semibold text-emerald-600 dark:text-emerald-400"
                      : "mt-1 flex items-center gap-2 font-semibold text-emerald-600 dark:text-emerald-400"
                  }
                >
                  {consent.optedOut ? (
                    <BellOffIcon className="size-4" aria-hidden />
                  ) : (
                    <CheckCircle2Icon className="size-4" aria-hidden />
                  )}
                  {consent.optedOut ? t.unsubscribed : t.subscribed}
                </dd>
              </div>
            </dl>

            <ConsentForm token={token} />
          </section>

          <section className="mt-6 rounded-2xl border border-hairline bg-background p-5">
            <h2 className="text-sm font-semibold text-foreground">{t.scopeTitle}</h2>
            <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
              {t.scope}
            </p>
          </section>
        </>
      ) : (
        <section className="mt-8 rounded-2xl border border-hairline bg-card p-5 sm:p-6">
          <div className="flex items-center gap-2 text-sm font-semibold text-foreground">
            <ShieldQuestionIcon className="size-4 text-electric" aria-hidden />
            {t.invalidTitle}
          </div>
          <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
            {t.invalidText}
          </p>
        </section>
      )}

      <p className="mt-8 text-center text-xs leading-relaxed text-muted-foreground">
        {t.sentBecause}
      </p>
    </div>
  );
}
