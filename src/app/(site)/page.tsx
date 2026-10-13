import type { Metadata } from "next";

import { About } from "@/components/landing/about";
import { CategoriesGrid } from "@/components/landing/categories-grid";
import { Certificates } from "@/components/landing/certificates";
import { Community } from "@/components/landing/community";
import { Faq } from "@/components/landing/faq";
import { FinalCta } from "@/components/landing/final-cta";
import { Hero } from "@/components/landing/hero";
import { HowItWorks } from "@/components/landing/how-it-works";
import { Institutions } from "@/components/landing/institutions";
import { Instructors } from "@/components/landing/instructors";
import { LiveClasses } from "@/components/landing/live-classes";
import { Method } from "@/components/landing/method";
import { PopularTracks } from "@/components/landing/popular-tracks";
import { Pricing } from "@/components/landing/pricing";
import { StatsBar } from "@/components/landing/stats-bar";
import { TrustBar } from "@/components/landing/trust-bar";
import {
  getCatalogNumbers,
  getCategories,
  getStartingPrices,
  getTracks,
} from "@/lib/catalog/queries";
import { getInstructorPlans } from "@/lib/instructor/plans";
import { categorySeo } from "@/config/seo";
import { site } from "@/config/site";

export const metadata: Metadata = {
  alternates: { canonical: "/" },
  keywords: [...site.keywords, ...Object.values(categorySeo).map((entry) => entry.primary)],
};

export default async function HomePage() {
  const [categories, tracks, startingPrices, numbers, instructorPlans] =
    await Promise.all([
      getCategories(),
      getTracks(),
      getStartingPrices(),
      getCatalogNumbers(),
      getInstructorPlans(),
    ]);

  return (
    <>
      {/* Bandeau d'ouverture : l'entête transparent se pose sur la même couleur. */}
      <div className="forest forest-band -mt-16 pt-16">
        <Hero />
        <StatsBar numbers={numbers} />
      </div>

      <TrustBar />
      <HowItWorks />
      <Method />
      <CategoriesGrid categories={categories} />
      <PopularTracks tracks={tracks} prices={startingPrices} />
      <Instructors plans={instructorPlans} />
      <LiveClasses />
      <Institutions />
      <Certificates />
      <Pricing />
      <Community />
      <Faq />
      <About />
      <FinalCta />
    </>
  );
}
