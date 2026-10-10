import type { PracticeChecklistItem, PracticeKind, PracticeTool } from "@/lib/practice/types";
import { createServerSupabase } from "@/lib/supabase/server";

type PracticeToolRow = {
  id: string;
  category_id: string;
  kind: string;
  label: string;
  config: unknown;
  enabled: boolean;
};

type PracticeToolConfig = {
  language?: string;
  items?: PracticeChecklistItem[];
};

function toPracticeTool(row: PracticeToolRow): PracticeTool {
  const config = (row.config ?? {}) as PracticeToolConfig;
  const items = Array.isArray(config.items)
    ? config.items.filter(
        (item): item is PracticeChecklistItem =>
          !!item && typeof item.label === "string" && item.label.length > 0,
      )
    : [];

  return {
    id: row.id,
    categoryId: row.category_id,
    kind: row.kind as PracticeKind,
    label: row.label,
    language: typeof config.language === "string" ? config.language : "",
    items,
    enabled: row.enabled,
  };
}

export async function getPracticeTool(
  categoryId: string,
): Promise<PracticeTool | null> {
  if (!categoryId) return null;
  const supabase = await createServerSupabase();
  if (!supabase) return null;

  const { data, error } = await supabase
    .from("practice_tools")
    .select("id,category_id,kind,label,config,enabled")
    .eq("category_id", categoryId)
    .eq("enabled", true)
    .maybeSingle();

  if (error) {
    console.error("[practice] tool", error.message);
    return null;
  }
  if (!data) return null;

  return toPracticeTool(data as PracticeToolRow);
}

export function practiceToolHasContent(
  tool: PracticeTool,
  starterCode: string,
  solutionCode: string,
): boolean {
  switch (tool.kind) {
    case "code_editor":
      return starterCode.trim().length > 0 || solutionCode.trim().length > 0;
    case "html_playground":
      return starterCode.trim().length > 0;
    case "lab_checklist":
      return tool.items.length > 0;
    default:
      return false;
  }
}
