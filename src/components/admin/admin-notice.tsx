import { Notice } from "@/components/auth/notice";
import { messages } from "@/i18n";

const t = messages.admin;

const notices: Record<string, { tone: "success" | "error"; text: string }> = {
  created: { tone: "success", text: t.created },
  updated: { tone: "success", text: t.updated },
  deleted: { tone: "success", text: t.deleted },
  saved: { tone: "success", text: t.pricing.saved },
  error: { tone: "error", text: t.saveFailed },
};

export function AdminNotice({ notice }: { notice?: string }) {
  if (!notice) return null;

  const entry = notices[notice];
  if (!entry) return null;

  return <Notice tone={entry.tone}>{entry.text}</Notice>;
}
