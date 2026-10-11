import type { EmailOtpType } from "@supabase/supabase-js";
import { NextResponse, type NextRequest } from "next/server";

import { resolveSiteUrl } from "@/config/site";
import { sanitizeInternalPath } from "@/lib/auth/validation";
import { createServerSupabase } from "@/lib/supabase/server";

const otpTypes = new Set([
  "signup",
  "invite",
  "magiclink",
  "recovery",
  "email_change",
  "email",
]);

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const tokenHash = searchParams.get("token_hash");
  const type = searchParams.get("type");
  const next = sanitizeInternalPath(searchParams.get("next"));
  const publicOrigin = resolveSiteUrl();

  if (tokenHash && type && otpTypes.has(type)) {
    const supabase = await createServerSupabase();
    if (supabase) {
      const { error } = await supabase.auth.verifyOtp({
        type: type as EmailOtpType,
        token_hash: tokenHash,
      });

      if (!error) {
        const path = next ?? "/auth/confirmation?statut=reussie";
        return NextResponse.redirect(new URL(path, publicOrigin));
      }
    }
  }

  return NextResponse.redirect(new URL("/auth/confirmation?statut=echec", publicOrigin));
}
