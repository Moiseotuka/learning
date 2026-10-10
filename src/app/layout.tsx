import type { Metadata, Viewport } from "next";
import { Inter, JetBrains_Mono } from "next/font/google";

import { EmailLinkRedirect } from "@/components/auth/email-link-redirect";
import { ThemeProvider } from "@/components/theme-provider";
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
    template: "%s · easyLearn",
  },
  description: messages.meta.description,
  keywords: [...site.keywords],
  applicationName: site.name,
  authors: [{ name: site.author }],
  alternates: { canonical: "/" },
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
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  themeColor: [
    { media: "(prefers-color-scheme: dark)", color: "#050914" },
    { media: "(prefers-color-scheme: light)", color: "#f4f7fc" },
  ],
};

const jsonLd = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      name: site.name,
      url: site.url,
      description: site.description,
      areaServed: "Afrique francophone",
      inLanguage: "fr",
    },
    {
      "@type": "WebSite",
      name: site.name,
      url: site.url,
      inLanguage: "fr",
      description: site.description,
    },
  ],
};

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
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
      </body>
    </html>
  );
}
