"use client";

import { Component, type ReactNode } from "react";
import { RefreshCcwIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";

const t = messages.learner;

type QuizErrorBoundaryProps = { children: ReactNode };
type QuizErrorBoundaryState = { failed: boolean };

export class QuizErrorBoundary extends Component<
  QuizErrorBoundaryProps,
  QuizErrorBoundaryState
> {
  state: QuizErrorBoundaryState = { failed: false };

  static getDerivedStateFromError(): QuizErrorBoundaryState {
    return { failed: true };
  }

  componentDidCatch(error: unknown) {
    console.error("[quiz] erreur inattendue", error);
  }

  render() {
    if (!this.state.failed) return this.props.children;

    return (
      <div className="rounded-2xl border border-destructive/40 bg-destructive/10 p-6 text-center">
        <p className="mx-auto max-w-md text-sm leading-relaxed text-foreground">
          {t.quizInterrupted}
        </p>
        <Button
          className="mt-5 h-10 px-4"
          onClick={() => window.location.reload()}
        >
          <RefreshCcwIcon aria-hidden />
          {t.reload}
        </Button>
      </div>
    );
  }
}
