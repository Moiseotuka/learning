import { CONTACT_EMAIL } from "@/config/contact";
import { site } from "@/config/site";

type JsonLd = Record<string, unknown>;

/**
 * Un donné structuré n'est valorisé que s'il décrit ce que l'internaute voit.
 * D'où l'absence volontaire d'`aggregateRating` : `tracks.rating` et
 * `tracks.students` sont des valeurs de remplissage, pas des avis réels.
 */
export function JsonLd({ data }: { data: JsonLd | JsonLd[] }) {
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(data) }}
    />
  );
}

export function breadcrumbLd(items: { name: string; path: string }[]): JsonLd {
  return {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: items.map((item, index) => ({
      "@type": "ListItem",
      position: index + 1,
      name: item.name,
      item: `${site.url}${item.path}`,
    })),
  };
}

/**
 * Recherche sitelinks : le moteur de recherche interne est déclaré comme
 * SearchAction, ce qui autorise le champ de recherche sous le résultat.
 */
export function webSiteLd(): JsonLd {
  return {
    "@context": "https://schema.org",
    "@type": "WebSite",
    name: site.name,
    url: site.url,
    inLanguage: "fr",
    description: site.description,
    potentialAction: {
      "@type": "SearchAction",
      target: {
        "@type": "EntryPoint",
        urlTemplate: `${site.url}/catalogue?q={search_term_string}`,
      },
      "query-input": "required name=search_term_string",
    },
  };
}

export function organizationLd(): JsonLd {
  return {
    "@context": "https://schema.org",
    "@type": "EducationalOrganization",
    name: site.name,
    url: site.url,
    description: site.description,
    areaServed: "Afrique francophone",
    inLanguage: "fr",
    email: CONTACT_EMAIL,
  };
}

export function courseLd(input: {
  title: string;
  description: string;
  category: string;
  levelLabel: string;
  durationHours: number;
  chapterCount: number;
  price: number | null;
  path: string;
  chapters: { title: string; summary: string }[];
}): JsonLd {
  const course: JsonLd = {
    "@type": "Course",
    name: input.title,
    description: input.description,
    inLanguage: "fr",
    category: input.category,
    educationalLevel: input.levelLabel,
    educationalUse: "Formation en ligne autofinancée",
    isAccessibleForFree: input.price === null || input.price === 0,
    provider: {
      "@type": "EducationalOrganization",
      name: site.name,
      url: site.url,
    },
    url: `${site.url}${input.path}`,
    timeRequired: `PT${input.durationHours}H`,
    hasCourseInstance: [
      {
        "@type": "CourseInstance",
        courseMode: "online",
        courseWorkload: `${input.chapterCount} leçons`,
      },
    ],
  };

  if (input.price !== null) {
    course.offers = {
      "@type": "Offer",
      category: "Formation",
      price: input.price,
      priceCurrency: "CDF",
      availability: "https://schema.org/InStock",
      url: `${site.url}${input.path}`,
    };
  }

  if (input.chapters.length > 0) {
    course.hasModule = input.chapters.map((chapter, index) => ({
      "@type": "LearningResource",
      name: chapter.title,
      description: chapter.summary,
      inLanguage: "fr",
      position: index + 1,
    }));
  }

  return { "@context": "https://schema.org", "@graph": [course] };
}

export function itemListLd(
  items: { name: string; path: string; description?: string }[],
  label: string,
): JsonLd {
  return {
    "@context": "https://schema.org",
    "@type": "ItemList",
    name: label,
    numberOfItems: items.length,
    itemListElement: items.map((item, index) => ({
      "@type": "ListItem",
      position: index + 1,
      url: `${site.url}${item.path}`,
      ...(item.description ? { description: item.description } : {}),
      name: item.name,
    })),
  };
}

export function faqLd(items: { q: string; a: string }[]): JsonLd {
  return {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: items.map((item) => ({
      "@type": "Question",
      name: item.q,
      acceptedAnswer: { "@type": "Answer", text: item.a },
    })),
  };
}
