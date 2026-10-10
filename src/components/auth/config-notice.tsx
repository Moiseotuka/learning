import { ConstructionIcon } from "lucide-react";

import { messages } from "@/i18n";

export function ConfigNotice() {
  return (
    <div className="flex items-start gap-3 rounded-xl border border-hairline bg-muted/40 p-4">
      <ConstructionIcon className="mt-0.5 size-4 shrink-0 text-electric" aria-hidden />
      <p className="text-sm leading-relaxed text-muted-foreground">
        {messages.auth.errors.notConfigured}
      </p>
    </div>
  );
}
