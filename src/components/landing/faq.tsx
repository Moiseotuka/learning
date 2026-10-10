import { Reveal } from "@/components/reveal";
import { Section, SectionHeading } from "@/components/section";
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion";
import { messages } from "@/i18n";

const t = messages;

export function Faq() {
  return (
    <Section id="faq" className="border-y border-hairline bg-elevated">
      <SectionHeading eyebrow={t.faq.eyebrow} title={t.faq.title} />

      <Reveal className="mx-auto max-w-3xl">
        <Accordion type="single" collapsible className="rounded-2xl border border-hairline bg-card px-5">
          {t.faq.items.map((item, index) => (
            <AccordionItem key={item.q} value={`faq-${index}`} className="border-hairline">
              <AccordionTrigger className="py-4 text-sm hover:no-underline sm:text-base">
                {item.q}
              </AccordionTrigger>
              <AccordionContent className="text-sm leading-relaxed text-muted-foreground">
                {item.a}
              </AccordionContent>
            </AccordionItem>
          ))}
        </Accordion>
      </Reveal>
    </Section>
  );
}
