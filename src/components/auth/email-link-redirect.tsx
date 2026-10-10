"use client";

import { useEffect } from "react";

import { links } from "@/config/site";
import { createBrowserSupabase } from "@/lib/supabase/client";
import { isSupabaseConfigured } from "@/lib/supabase/config";

function destinationFor(type: string | null) {
  if (type === "recovery") return links.resetPassword;
  if (type === "signup" || type === "email") return "/auth/confirmation?statut=reussie";
  return null;
}

export function EmailLinkRedirect() {
  useEffect(() => {
    if (!isSupabaseConfigured) return;

    const hash = window.location.hash.slice(1);
    if (!hash) return;

    const params = new URLSearchParams(hash);
    const destination = destinationFor(params.get("type"));
    if (!destination) return;
    if (window.location.pathname === new URL(destination, window.location.origin).pathname) {
      return;
    }

    const supabase = createBrowserSupabase();
    if (!supabase) return;

    supabase.auth
      .getSession()
      .then(({ data }) => {
        if (data.session) window.location.replace(destination);
      })
      .catch(() => undefined);
  }, []);

  return null;
}
