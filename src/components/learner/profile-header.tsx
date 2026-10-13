"use client";

import {
  Loader2Icon,
  MailIcon,
  PencilIcon,
  PhoneIcon,
  UploadIcon,
} from "lucide-react";
import { useRouter } from "next/navigation";
import { useEffect, useRef, useState, useActionState } from "react";

import { AuthField } from "@/components/auth/auth-field";
import { Notice } from "@/components/auth/notice";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { messages } from "@/i18n";
import { updateProfile, uploadAvatar } from "@/lib/actions/profil";

const t = messages.learner.profil;

type ProfileHeaderProps = {
  name: string;
  email: string;
  phone: string | null;
  avatarUrl: string | null;
  role: string;
};

function initialsOf(name: string): string {
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase() ?? "")
    .join("");
}

export function ProfileHeader({
  name,
  email,
  phone,
  avatarUrl,
  role,
}: ProfileHeaderProps) {
  const router = useRouter();
  const fileRef = useRef<HTMLInputElement>(null);
  const [open, setOpen] = useState(false);
  const [avatar, setAvatar] = useState(avatarUrl);
  const [uploading, setUploading] = useState(false);
  const [photoError, setPhotoError] = useState("");
  const [state, action, pending] = useActionState(updateProfile, undefined);

  useEffect(() => {
    if (state?.status === "success" || state?.status === "email-pending") {
      router.refresh();
    }
  }, [state, router]);

  async function handleFileChange(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    event.target.value = "";
    if (!file) return;

    setUploading(true);
    setPhotoError("");
    const result = await uploadAvatar(file);
    if (result.status === "success" && result.avatarUrl) {
      setAvatar(result.avatarUrl);
      router.refresh();
    } else {
      setPhotoError(result.message ?? t.form.errors.generic);
    }
    setUploading(false);
  }

  const roleLabel =
    t.role[role as keyof typeof t.role] ?? t.role.learner;
  const success =
    state?.status === "success" || state?.status === "email-pending";

  return (
    <section className="rounded-2xl border border-hairline bg-card p-5 shadow-sm sm:p-6">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div className="flex min-w-0 items-start gap-4 sm:gap-5">
          <Avatar className="size-20 shrink-0 rounded-2xl">
            {avatar ? <AvatarImage src={avatar} alt={name} /> : null}
            <AvatarFallback className="rounded-2xl bg-electric/12 text-lg text-electric">
              {initialsOf(name)}
            </AvatarFallback>
          </Avatar>

          <div className="min-w-0">
            <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
              {t.identity}
            </p>
            <h1 className="mt-1 truncate text-2xl font-semibold tracking-tight text-foreground">
              {name}
            </h1>
            <p className="mt-1 inline-flex items-center rounded-full bg-electric/12 px-2.5 py-0.5 text-xs font-medium text-electric">
              {roleLabel}
            </p>

            <div className="mt-3 flex flex-col gap-1.5 text-sm text-muted-foreground">
              <span className="inline-flex min-w-0 items-center gap-2">
                <MailIcon className="size-4 shrink-0 text-electric" aria-hidden />
                <span className="truncate">{email}</span>
              </span>
              <span className="inline-flex min-w-0 items-center gap-2">
                <PhoneIcon className="size-4 shrink-0 text-electric" aria-hidden />
                <span className={phone ? "truncate" : "italic"}>
                  {phone || t.noPhone}
                </span>
              </span>
            </div>
          </div>
        </div>

        <Button
          type="button"
          size="sm"
          className="h-9 shrink-0"
          onClick={() => setOpen(true)}
        >
          <PencilIcon className="size-4" aria-hidden />
          {t.edit}
        </Button>
      </div>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{t.form.title}</DialogTitle>
            <DialogDescription>{t.form.description}</DialogDescription>
          </DialogHeader>

          <form action={action} className="space-y-4">
            <div className="space-y-1.5">
              <p className="block text-sm font-medium text-foreground">
                {t.form.photo}
              </p>
              <div className="flex items-center gap-3">
                <Avatar className="size-14 shrink-0 rounded-2xl">
                  {avatar ? <AvatarImage src={avatar} alt={name} /> : null}
                  <AvatarFallback className="rounded-2xl bg-electric/12 text-electric">
                    {initialsOf(name)}
                  </AvatarFallback>
                </Avatar>
                <div className="min-w-0">
                  <input
                    ref={fileRef}
                    id="avatar-file"
                    type="file"
                    accept="image/jpeg,image/png,image/webp"
                    className="sr-only"
                    onChange={handleFileChange}
                    disabled={uploading}
                  />
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    className="h-9 border-hairline bg-background"
                    disabled={uploading}
                    onClick={() => fileRef.current?.click()}
                  >
                    {uploading ? (
                      <Loader2Icon className="size-4 animate-spin" aria-hidden />
                    ) : (
                      <UploadIcon className="size-4" aria-hidden />
                    )}
                    {uploading ? t.form.photoUploading : t.form.photoChoose}
                  </Button>
                  <p className="mt-1 text-xs text-muted-foreground">
                    {t.form.photoHint}
                  </p>
                </div>
              </div>
              {photoError ? (
                <p className="text-xs font-medium text-destructive">
                  {photoError}
                </p>
              ) : null}
            </div>

            <AuthField
              id="fullName"
              label={t.form.fullName}
              error={state?.fieldErrors?.fullName}
            >
              <Input
                id="fullName"
                name="fullName"
                defaultValue={name}
                maxLength={100}
                required
                aria-invalid={Boolean(state?.fieldErrors?.fullName)}
                className="h-11"
              />
            </AuthField>

            <AuthField
              id="email"
              label={t.form.email}
              hint={t.form.emailHint}
              error={state?.fieldErrors?.email}
            >
              <Input
                id="email"
                name="email"
                type="email"
                defaultValue={email}
                required
                aria-invalid={Boolean(state?.fieldErrors?.email)}
                className="h-11"
              />
            </AuthField>

            <AuthField
              id="phone"
              label={t.form.phone}
              error={state?.fieldErrors?.phone}
            >
              <Input
                id="phone"
                name="phone"
                type="tel"
                defaultValue={phone ?? ""}
                placeholder="+243 81 234 5678"
                aria-invalid={Boolean(state?.fieldErrors?.phone)}
                className="h-11"
              />
            </AuthField>

            {state?.message ? (
              <Notice tone={state.status === "error" ? "error" : success ? "success" : "info"}>
                {state.message}
              </Notice>
            ) : null}

            <DialogFooter>
              <Button
                type="button"
                variant="outline"
                className="border-hairline bg-background"
                onClick={() => setOpen(false)}
              >
                {t.form.cancel}
              </Button>
              <Button type="submit" disabled={pending} className="h-11">
                {pending ? (
                  <Loader2Icon className="size-4 animate-spin" aria-hidden />
                ) : null}
                {t.form.save}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </section>
  );
}
