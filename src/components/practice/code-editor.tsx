"use client";

import { html } from "@codemirror/lang-html";
import { javascript } from "@codemirror/lang-javascript";
import { python } from "@codemirror/lang-python";
import { EditorView } from "@codemirror/view";
import CodeMirror from "@uiw/react-codemirror";
import { useTheme } from "next-themes";
import { useMemo } from "react";

type CodeEditorProps = {
  language: string;
  value: string;
  onChange?: (value: string) => void;
  readOnly?: boolean;
  minHeight?: string;
};

function languageExtension(language: string) {
  switch (language) {
    case "python":
      return python();
    case "html":
      return html();
    case "jsx":
      return javascript({ jsx: true });
    case "typescript":
      return javascript({ typescript: true });
    case "tsx":
      return javascript({ typescript: true, jsx: true });
    case "javascript":
    case "js":
      return javascript();
    default:
      return [];
  }
}

export default function CodeEditor({
  language,
  value,
  onChange,
  readOnly = false,
  minHeight = "14rem",
}: CodeEditorProps) {
  const { resolvedTheme } = useTheme();
  const extensions = useMemo(
    () => [languageExtension(language), EditorView.lineWrapping],
    [language],
  );

  return (
    <div
      className="overflow-hidden rounded-xl border border-hairline bg-background"
      style={{ minHeight }}
    >
      <CodeMirror
        value={value}
        onChange={onChange}
        theme={resolvedTheme === "light" ? "light" : "dark"}
        readOnly={readOnly}
        editable={!readOnly}
        extensions={extensions}
        basicSetup={{
          lineNumbers: true,
          foldGutter: false,
          highlightActiveLine: !readOnly,
          autocompletion: false,
          bracketMatching: true,
        }}
      />
    </div>
  );
}
