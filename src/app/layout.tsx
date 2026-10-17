import type { Metadata, Viewport } from "next";
import { Inter, JetBrains_Mono } from "next/font/google";

import { EmailLinkRedirect } from "@/components/auth/email-link-redirect";
import { ThemeProvider } from "@/components/theme-provider";
import { JsonLd, organizationLd, webSiteLd } from "@/components/seo/json-ld";
import { site } from "@/config/site";
import { messages } from "@/i18n";

import "./globals.css";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  display: "swap",
});

const jetbrainsMono = JetBrains_Mono({
  variable: "--font-mono-code",
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  metadataBase: new URL(site.url),
  title: {
    default: messages.meta.title,
    template: "%s · easyTech",
  },
  description: messages.meta.description,
  keywords: [...site.keywords],
  applicationName: site.name,
  authors: [{ name: site.author }],
  // Pas de canonical ici : l'objet `alternates` s'hérite par fusion, donc un
  // canonical racine ferait de « / » la version canonique de TOUTES les pages,
  // y compris le catalogue et les fiches parcours. Chaque page déclare le sien.
  openGraph: {
    type: "website",
    locale: "fr_FR",
    url: site.url,
    siteName: site.name,
    title: messages.meta.title,
    description: messages.meta.description,
  },
  twitter: {
    card: "summary_large_image",
    title: messages.meta.title,
    description: messages.meta.description,
  },
  robots: { index: true, follow: true },
  // Double assurance pour Google Search Console : cette balise et le fichier
  // public/google9a93affa0135a93b.html vérifient tous deux la propriété
  // « https://elearning-three-phi.vercel.app ». L'un des deux suffit, et un
  // redéploiement ne peut plus casser la vérification.
  other: {
    "google-site-verification": "vIT5Gzw5DNm9Ru-ceV0OO8aWdFuDOMB15zXmbyvDK0s",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  themeColor: [
    { media: "(prefers-color-scheme: dark)", color: "#04140d" },
    { media: "(prefers-color-scheme: light)", color: "#ffffff" },
  ],
};

const jsonLd = [organizationLd(), webSiteLd()];

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="fr"
      suppressHydrationWarning
      data-scroll-behavior="smooth"
      className={`${inter.variable} ${jetbrainsMono.variable} h-full antialiased`}
    >
      <body className="flex min-h-full flex-col font-sans">
        <EmailLinkRedirect />
        <ThemeProvider>{children}</ThemeProvider>
        <JsonLd data={jsonLd} />
      </body>
    </html>
  );
}
