"use client";

import { useEffect } from "react";

import { links } from "@/config/site";
import { createBrowserSupabase } from "@/lib/supabase/client";
import { isSupabaseConfigured } from "@/lib/supabase/config";

function destinationFor(type: string | null, hash: URLSearchParams) {
  if (type === "recovery" || hash.has("access_token")) {
    return links.resetPassword;
  }
  if (type === "signup" || type === "email") return "/auth/confirmation?statut=reussie";
  return null;
}

export function EmailLinkRedirect() {
  useEffect(() => {
    if (!isSupabaseConfigured) return;

    const hash = new URLSearchParams(window.location.hash.slice(1));
    const search = new URLSearchParams(window.location.search);
    const destination = destinationFor(
      hash.get("type") ?? search.get("type"),
      hash,
    );
    if (!destination) return;
    if (
      window.location.pathname ===
      new URL(destination, window.location.origin).pathname
    ) {
      return;
    }

    const supabase = createBrowserSupabase();
    if (!supabase) return;

    supabase.auth
      .getSession()
      .then(({ data }) => {
        if (data.session || hash.has("access_token")) {
          window.location.replace(destination);
        }
      })
      .catch(() => undefined);
  }, []);

  return null;
}
