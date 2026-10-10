export type PracticeKind =
  | "code_editor"
  | "html_playground"
  | "lab_checklist"
  | "terminal_simule"
  | "aucun";

export type PracticeChecklistItem = {
  label: string;
  hint?: string;
};

export type PracticeTool = {
  id: string;
  categoryId: string;
  kind: PracticeKind;
  label: string;
  language: string;
  items: PracticeChecklistItem[];
  enabled: boolean;
};
