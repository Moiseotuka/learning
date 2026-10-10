import { About } from "@/components/landing/about";
import { CategoriesGrid } from "@/components/landing/categories-grid";
import { Certificates } from "@/components/landing/certificates";
import { Community } from "@/components/landing/community";
import { Faq } from "@/components/landing/faq";
import { FinalCta } from "@/components/landing/final-cta";
import { Hero } from "@/components/landing/hero";
import { HowItWorks } from "@/components/landing/how-it-works";
import { Instructors } from "@/components/landing/instructors";
import { Method } from "@/components/landing/method";
import { PopularTracks } from "@/components/landing/popular-tracks";
import { Pricing } from "@/components/landing/pricing";
import { StatsBar } from "@/components/landing/stats-bar";
import { Testimonials } from "@/components/landing/testimonials";
import { TrustBar } from "@/components/landing/trust-bar";
import { LevelUpNotification } from "@/components/learning/level-up-banner";
import { getCategories, getStartingPrices, getTracks } from "@/lib/catalog/queries";
import { links } from "@/config/site";
import { messages } from "@/i18n";

export default async function HomePage() {
  const [categories, tracks, startingPrices] = await Promise.all([
    getCategories(),
    getTracks(),
    getStartingPrices(),
  ]);

  return (
    <>
      <Hero />
      <StatsBar />
      <TrustBar />
      <HowItWorks />
      <Method />
      <CategoriesGrid categories={categories} />
      <PopularTracks tracks={tracks} prices={startingPrices} />
      <Certificates />
      <Instructors />
      <Testimonials />
      <Pricing />
      <Community />
      <Faq />
      <About />
      <FinalCta />
      <LevelUpNotification
        ctaHref={links.signup}
        ctaLabel={messages.hero.primaryCta}
      />
    </>
  );
}
