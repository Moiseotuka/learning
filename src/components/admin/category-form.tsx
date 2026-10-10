"use client";

import { Loader2Icon } from "lucide-react";
import Link from "next/link";
import { useActionState, type ReactNode } from "react";

import { Notice } from "@/components/auth/notice";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { levels, type LevelType } from "@/config/catalog";
import { links } from "@/config/site";
import { messages } from "@/i18n";
import { saveCategory } from "@/lib/actions/admin";
import type { AdminCategory } from "@/lib/catalog/queries";
import { cn } from "cn";

const t = messages.admin;

const iconOptions = [
  { value: "terminal", label: "Terminal" },
  { value: "layout", label: "Interface" },
  { value: "brain", label: "Intelligence artificielle" },
  { value: "shield", label: "Bouclier" },
  { value: "network", label: "Réseau" },
  { value: "cpu", label: "Processeur" },
  { value: "circuit", label: "Circuit" },
  { value: "atom", label: "Atome" },
  { value: "robot", label: "Robot" },
  { value: "cloud", label: "Cloud" },
];

function Field({
  label,
  htmlFor,
  error,
  hint,
  children,
}: {
  label: string;
  htmlFor: string;
  error?: string;
  hint?: string;
  children: ReactNode;
}) {
  return (
    <div className="space-y-1.5">
      <label htmlFor={htmlFor} className="text-sm font-medium text-foreground">
        {label}
      </label>
      {children}
      {hint && !error ? (
        <p className="text-xs text-muted-foreground">{hint}</p>
      ) : null}
      {error ? (
        <p id={`${htmlFor}-error`} className="text-xs text-destructive">
          {error}
        </p>
      ) : null}
    </div>
  );
}

export function CategoryForm({ category }: { category?: AdminCategory }) {
  const [state, action, pending] = useActionState(saveCategory, undefined);

  const nameError = state?.fieldErrors?.name;
  const slugError = state?.fieldErrors?.slug;
  const levelsError = state?.fieldErrors?.levels;
  const positionError = state?.fieldErrors?.position;

  return (
    <form action={action} className="space-y-5">
      {state?.message ? <Notice tone="error">{state.message}</Notice> : null}

      {category ? <input type="hidden" name="id" value={category.id} /> : null}

      <div className="grid gap-4 sm:grid-cols-2">
        <Field label={t.fields.name} htmlFor="name" error={nameError}>
          <Input
            id="name"
            name="name"
            defaultValue={category?.name ?? ""}
            placeholder={t.fields.namePlaceholder}
            required
            aria-invalid={Boolean(nameError)}
            aria-describedby={nameError ? "name-error" : undefined}
            className="h-10"
          />
        </Field>

        <Field
          label={t.fields.slug}
          htmlFor="slug"
          error={slugError}
          hint={t.fields.slugHint}
        >
          <Input
            id="slug"
            name="slug"
            defaultValue={category?.slug ?? ""}
            placeholder={t.fields.slugPlaceholder}
            required
            aria-invalid={Boolean(slugError)}
            aria-describedby={slugError ? "slug-error" : undefined}
            className="h-10"
          />
        </Field>
      </div>

      <Field
        label={t.fields.description}
        htmlFor="description"
        error={state?.fieldErrors?.description}
      >
        <textarea
          id="description"
          name="description"
          defaultValue={category?.description ?? ""}
          rows={3}
          placeholder={t.fields.descriptionPlaceholder}
          className={cn(
            "w-full rounded-lg border border-input bg-transparent px-2.5 py-2 text-sm outline-none transition-colors",
            "placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50",
            "aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20",
          )}
        />
      </Field>

      <div className="grid gap-4 sm:grid-cols-2">
        <Field label={t.fields.icon} htmlFor="icon">
          <select
            id="icon"
            name="icon"
            defaultValue={category?.icon ?? "terminal"}
            className={cn(
              "h-10 w-full rounded-lg border border-input bg-transparent px-2.5 text-sm outline-none transition-colors",
              "focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50",
            )}
          >
            {iconOptions.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </Field>

        <Field
          label={t.fields.position}
          htmlFor="position"
          error={positionError}
        >
          <Input
            id="position"
            name="position"
            type="number"
            min={0}
            defaultValue={category?.position ?? 0}
            aria-invalid={Boolean(positionError)}
            aria-describedby={positionError ? "position-error" : undefined}
            className="h-10"
          />
        </Field>
      </div>

      <Field
        label={t.fields.levels}
        htmlFor="levels-debutant"
        error={levelsError}
      >
        <div className="flex flex-wrap gap-3 pt-1">
          {levels.map((level: LevelType) => (
            <label
              key={level}
              htmlFor={`levels-${level}`}
              className="inline-flex cursor-pointer items-center gap-2 rounded-lg border border-hairline px-3 py-2 text-sm text-foreground"
            >
              <input
                id={`levels-${level}`}
                type="checkbox"
                name="levels"
                value={level}
                defaultChecked={
                  category ? category.levels.includes(level) : level === "debutant"
                }
                className="size-4 accent-electric"
              />
              {messages.common.levels[level]}
            </label>
          ))}
        </div>
      </Field>

      <label
        htmlFor="published"
        className="flex cursor-pointer items-start gap-2.5 rounded-xl border border-hairline bg-muted/30 px-3.5 py-3"
      >
        <input
          id="published"
          type="checkbox"
          name="published"
          defaultChecked={category ? category.published : true}
          className="mt-0.5 size-4 accent-electric"
        />
        <span>
          <span className="block text-sm font-medium text-foreground">
            {t.fields.published}
          </span>
          <span className="block text-xs text-muted-foreground">
            {t.fields.publishedHint}
          </span>
        </span>
      </label>

      <div className="flex items-center gap-3 border-t border-hairline pt-4">
        <Button type="submit" disabled={pending} className="h-10 px-5">
          {pending ? <Loader2Icon className="animate-spin" aria-hidden /> : null}
          {t.actions.save}
        </Button>
        <Button asChild type="button" variant="outline" className="h-10 px-4">
          <Link href={`${links.admin}/categories`}>{t.actions.cancel}</Link>
        </Button>
      </div>
    </form>
  );
}
