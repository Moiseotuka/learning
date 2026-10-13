import type { Metadata } from "next";

import { messages } from "@/i18n";
import { createServiceSupabase } from "@/lib/supabase/service";

const t = messages.auth;

export const metadata: Metadata = {
  title: t.verifyTitle,
  robots: { index: false },
};

type CertificateRow = {
  code: string;
  title: string;
  full_name: string;
  issued_at: string;
};

function formatDate(iso: string): string {
  return new Intl.DateTimeFormat("fr-FR", {
    day: "numeric",
    month: "long",
    year: "numeric",
  }).format(new Date(iso));
}

export default async function VerifyPage(props: PageProps<"/verifier">) {
  const searchParams = await props.searchParams;
  const code =
    typeof searchParams.code === "string" ? searchParams.code.trim() : "";

  let certificate: CertificateRow | null = null;
  let searched = false;

  if (code) {
    searched = true;
    const supabase = createServiceSupabase();
    if (supabase) {
      const { data, error } = await supabase
        .from("certificates")
        .select("code,title,full_name,issued_at")
        .eq("code", code)
        .maybeSingle();

      if (error) {
        console.error("[verify] lookup", error.message);
      } else {
        certificate = (data as CertificateRow | null) ?? null;
      }
    }
  }

  return (
    <div className="mx-auto w-full max-w-xl px-4 py-12 sm:px-6 lg:py-16">
      <header className="text-center">
        <p className="text-xs font-semibold uppercase tracking-wider text-electric">
          easyTech
        </p>
        <h1 className="mt-2 text-3xl font-semibold tracking-tight text-foreground">
          {t.verifyTitle}
        </h1>
      </header>

      <form
        method="get"
        action="/verifier"
        className="mt-8 rounded-2xl border border-hairline bg-card p-5 sm:p-6"
      >
        <label
          htmlFor="code"
          className="text-sm font-medium text-foreground"
        >
          {t.verifyForm.label}
        </label>
        <div className="mt-2 flex gap-2">
          <input
            id="code"
            name="code"
            type="text"
            defaultValue={code}
            placeholder={t.verifyForm.placeholder}
            className="h-10 w-full min-w-0 rounded-lg border border-input bg-background px-3 text-sm text-foreground placeholder:text-muted-foreground focus:border-electric focus:outline-none focus:ring-1 focus:ring-electric"
          />
          <button
            type="submit"
            className="h-10 shrink-0 rounded-lg bg-electric px-4 text-sm font-semibold text-primary-foreground transition-colors hover:bg-electric/90"
          >
            {t.verifyForm.submit}
          </button>
        </div>
        <p className="mt-2 text-xs text-muted-foreground">{t.verifyForm.hint}</p>
      </form>

      {searched ? (
        certificate ? (
          <section className="mt-6 rounded-2xl border border-emerald-500/40 bg-emerald-500/[0.06] p-5 sm:p-6">
            <div className="flex items-center gap-2 text-sm font-semibold text-emerald-600 dark:text-emerald-400">
              <svg
                aria-hidden
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                className="size-4"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"
                />
              </svg>
              {t.verifyValid}
            </div>
            <dl className="mt-4 space-y-3 text-sm">
              <div>
                <dt className="text-xs uppercase tracking-wider text-muted-foreground">
                  {t.verifyHolder}
                </dt>
                <dd className="mt-0.5 font-semibold text-foreground">
                  {certificate.full_name}
                </dd>
              </div>
              <div>
                <dt className="text-xs uppercase tracking-wider text-muted-foreground">
                  {t.verifyFormation}
                </dt>
                <dd className="mt-0.5 font-semibold text-foreground">
                  {certificate.title}
                </dd>
              </div>
              <div className="flex flex-wrap gap-x-8 gap-y-2">
                <div>
                  <dt className="text-xs uppercase tracking-wider text-muted-foreground">
                    {t.verifyCode}
                  </dt>
                  <dd className="mt-0.5 tabular-nums text-foreground">
                    {certificate.code}
                  </dd>
                </div>
                <div>
                  <dt className="text-xs uppercase tracking-wider text-muted-foreground">
                    {t.verifyIssuedLabel}
                  </dt>
                  <dd className="mt-0.5 tabular-nums text-foreground">
                    {formatDate(certificate.issued_at)}
                  </dd>
                </div>
              </div>
            </dl>
          </section>
        ) : (
          <section className="mt-6 rounded-2xl border border-amber-500/40 bg-amber-500/[0.06] p-5 sm:p-6">
            <p className="text-sm font-semibold text-amber-600 dark:text-amber-400">
              {t.verifyInvalid}
            </p>
            <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
              {t.verifyInvalidText}
            </p>
          </section>
        )
      ) : null}
    </div>
  );
}
