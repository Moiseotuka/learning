import { createServerClient } from "@supabase/ssr";
import type { User } from "@supabase/supabase-js";
import { NextResponse, type NextRequest } from "next/server";

import { links } from "@/config/site";
import { sanitizeInternalPath } from "@/lib/auth/validation";
import { getSupabaseEnv } from "@/lib/supabase/config";

const protectedPaths = ["/app", "/admin"];
const authPaths: string[] = [links.login, links.signup];

function isPath(path: string, prefixes: string[]) {
  return prefixes.some((prefix) => path === prefix || path.startsWith(`${prefix}/`));
}

function hasSessionCookie(request: NextRequest) {
  return request.cookies
    .getAll()
    .some((cookie) => cookie.name.startsWith("sb-") && cookie.name.includes("auth-token"));
}

function copyCookies(from: NextResponse, to: NextResponse) {
  for (const cookie of from.cookies.getAll()) {
    to.cookies.set(cookie);
  }
}

export async function proxy(request: NextRequest) {
  const env = getSupabaseEnv();
  if (!env) return NextResponse.next();

  const { pathname, search } = request.nextUrl;
  const response = NextResponse.next({ request });

  const supabase = createServerClient(env.url, env.anonKey, {
    cookies: {
      getAll: () => request.cookies.getAll(),
      setAll: (cookiesToSet) => {
        for (const { name, value, options } of cookiesToSet) {
          request.cookies.set({ name, value });
          response.cookies.set({ name, value, ...options });
        }
      },
    },
  });

  let user: User | null = null;
  if (hasSessionCookie(request)) {
    const { data } = await supabase.auth.getUser();
    user = data.user;
  }

  if (!user && isPath(pathname, protectedPaths)) {
    const url = new URL(links.login, request.url);
    url.searchParams.set("next", `${pathname}${search}`);
    const redirect = NextResponse.redirect(url);
    copyCookies(response, redirect);
    return redirect;
  }

  if (user && authPaths.includes(pathname)) {
    // Un apprenant deja connecte qui suit un lien « Commencer gratuitement » doit
    // arriver sur le parcours vise, pas etre rejete sur la page d'accueil.
    const next = sanitizeInternalPath(request.nextUrl.searchParams.get("next"));
    const redirect = NextResponse.redirect(new URL(next ?? links.home, request.url));
    copyCookies(response, redirect);
    return redirect;
  }

  return response;
}

export const config = {
  matcher: [
    "/((?!api|_next/static|_next/image|favicon.ico|icon.svg|.*\\.(?:png|jpg|jpeg|gif|webp|svg|ico|woff2?)$).*)",
  ],
};
