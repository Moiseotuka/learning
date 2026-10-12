import { About } from "@/components/landing/about";
import { CategoriesGrid } from "@/components/landing/categories-grid";
import { Certificates } from "@/components/landing/certificates";
import { Community } from "@/components/landing/community";
import { Faq } from "@/components/landing/faq";
import { FinalCta } from "@/components/landing/final-cta";
import { Hero } from "@/components/landing/hero";
import { HowItWorks } from "@/components/landing/how-it-works";
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

export default async function HomePage() {
  const [categories, tracks, startingPrices, numbers] = await Promise.all([
    getCategories(),
    getTracks(),
    getStartingPrices(),
    getCatalogNumbers(),
  ]);

  return (
    <>
      <Hero />
      <StatsBar numbers={numbers} />
      <TrustBar />
      <HowItWorks />
      <Method />
      <CategoriesGrid categories={categories} />
      <PopularTracks tracks={tracks} prices={startingPrices} />
      <Certificates />
      <Pricing />
      <Community />
      <Faq />
      <About />
      <FinalCta />
    </>
  );
}
