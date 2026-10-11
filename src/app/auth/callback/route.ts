import { NextResponse, type NextRequest } from "next/server";

import { links, resolveSiteUrl } from "@/config/site";
import { sanitizeInternalPath } from "@/lib/auth/validation";
import { createServerSupabase } from "@/lib/supabase/server";

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const code = searchParams.get("code");
  const error = searchParams.get("error");
  const errorDescription = searchParams.get("error_description");
  const next = sanitizeInternalPath(searchParams.get("next")) ?? links.home;
  const publicOrigin = resolveSiteUrl();

  if (error) {
    const isStateReuse =
      error === "invalid_request" ||
      error === "access_denied" ||
      (errorDescription ?? "").toLowerCase().includes("state") ||
      (errorDescription ?? "").toLowerCase().includes("already been used") ||
      (errorDescription ?? "").toLowerCase().includes("expired");

    return NextResponse.redirect(
      new URL(`${links.login}?erreur=${isStateReuse ? "oauth-state" : "google"}`, publicOrigin),
    );
  }

  if (code) {
    const supabase = await createServerSupabase();
    if (supabase) {
      const { error } = await supabase.auth.exchangeCodeForSession(code);
      if (!error) return NextResponse.redirect(new URL(next, publicOrigin));
    }
  }

  return NextResponse.redirect(new URL(`${links.login}?erreur=connexion`, publicOrigin));
}
