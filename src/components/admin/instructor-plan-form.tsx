"use client";

import { Loader2Icon } from "lucide-react";
import { useActionState } from "react";

import { Notice } from "@/components/auth/notice";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { messages } from "@/i18n";
import { createInstructorPlan } from "@/lib/actions/admin";
import { cn } from "cn";

const t = messages.admin;

const field =
  "h-10 w-full rounded-lg border border-input bg-transparent px-2.5 text-sm outline-none transition-colors placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 aria-invalid:border-destructive";

function Label({ htmlFor, text }: { htmlFor: string; text: string }) {
  return (
    <label htmlFor={htmlFor} className="mb-1.5 block text-xs font-medium text-muted-foreground">
      {text}
    </label>
  );
}

export function InstructorPlanForm() {
  const [state, action, pending] = useActionState(createInstructorPlan, undefined);
  const errors = state?.fieldErrors ?? {};

  return (
    <form action={action} className="space-y-4">
      {state?.status === "error" && state.message ? (
        <Notice tone="error">{state.message}</Notice>
      ) : null}

      <div className="grid gap-3 sm:grid-cols-2">
        <div>
          <Label htmlFor="code" text={t.plans.fields.code} />
          <input
            id="code"
            name="code"
            required
            pattern="[a-z][a-z0-9_]{1,30}"
            placeholder="deux_mois"
            aria-invalid={Boolean(errors.code)}
            aria-describedby={errors.code ? "code-error" : "code-hint"}
            className={cn(field, "font-mono")}
          />
          <p
            id={errors.code ? "code-error" : "code-hint"}
            className={cn(
              "mt-1.5 text-[11px]",
              errors.code ? "text-destructive" : "text-muted-foreground",
            )}
          >
            {errors.code ?? t.plans.codeHint}
          </p>
        </div>

        <div>
          <Label htmlFor="label" text={t.plans.fields.label} />
          <Input
            id="label"
            name="label"
            required
            minLength={2}
            placeholder={t.plans.labelPlaceholder}
            aria-invalid={Boolean(errors.label)}
            className={cn(field, "h-10")}
          />
        </div>

        <div>
          <Label htmlFor="days" text={t.plans.fields.days} />
          <Input
            id="days"
            name="days"
            type="number"
            min={1}
            max={3650}
            required
            placeholder="60"
            aria-invalid={Boolean(errors.days)}
            className={cn(field, "tabular-nums")}
          />
        </div>

        <div>
          <Label htmlFor="price" text={t.plans.fields.price} />
          <Input
            id="price"
            name="price"
            type="number"
            min={0}
            step={500}
            required
            placeholder="45000"
            aria-invalid={Boolean(errors.price)}
            className={cn(field, "tabular-nums")}
          />
        </div>

        <div>
          <Label htmlFor="seats" text={t.plans.fields.seats} />
          <Input
            id="seats"
            name="seats"
            type="number"
            min={1}
            max={2000}
            required
            defaultValue={25}
            aria-invalid={Boolean(errors.seats)}
            className={cn(field, "tabular-nums")}
          />
        </div>

        <div>
          <Label htmlFor="tracks" text={t.plans.fields.tracks} />
          <Input
            id="tracks"
            name="tracks"
            type="number"
            min={1}
            max={200}
            required
            placeholder="4"
            aria-invalid={Boolean(errors.tracks)}
            className={cn(field, "tabular-nums")}
          />
        </div>

        <div>
          <Label htmlFor="discount" text={t.plans.fields.discount} />
          <Input
            id="discount"
            name="discount"
            type="number"
            min={0}
            max={90}
            defaultValue={0}
            className={cn(field, "tabular-nums")}
          />
        </div>

        <div>
          <Label htmlFor="highlight" text={t.plans.fields.highlight} />
          <Input id="highlight" name="highlight" placeholder="Le plus choisi" className={field} />
        </div>
      </div>

      <Button type="submit" className="h-10 px-5" disabled={pending}>
        {pending ? <Loader2Icon className="animate-spin" aria-hidden /> : null}
        {t.plans.create}
      </Button>
    </form>
  );
}
