"use client";

import { Loader2Icon } from "lucide-react";
import { useTransition } from "react";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { messages } from "@/i18n";
import { deleteCategory } from "@/lib/actions/admin";

const t = messages.admin;

export function DeleteCategoryButton({ id }: { id: string }) {
  const [pending, startTransition] = useTransition();

  return (
    <Dialog>
      <DialogTrigger asChild>
        <Button
          type="button"
          variant="ghost"
          size="sm"
          className="text-destructive hover:bg-destructive/10 hover:text-destructive"
          disabled={pending}
        >
          {t.actions.delete}
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{t.deleteTitle}</DialogTitle>
          <DialogDescription>{t.deleteText}</DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <DialogClose asChild>
            <Button type="button" variant="outline">
              {t.actions.cancel}
            </Button>
          </DialogClose>
          <form
            action={(formData) => startTransition(() => deleteCategory(formData))}
            className="contents"
          >
            <input type="hidden" name="id" value={id} />
            <Button type="submit" variant="destructive" disabled={pending}>
              {pending ? (
                <Loader2Icon className="animate-spin" aria-hidden />
              ) : null}
              {t.actions.confirm}
            </Button>
          </form>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
