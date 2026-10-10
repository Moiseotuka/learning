"use client";

/** Résultat d'une exécution envoyée au worker (voir public/pyodide-worker.js). */
export type RunOutcome = {
  ok: boolean;
  stdout: string;
  stderr: string;
  error?: string;
  /** Vrai si l'exécution a été interrompue par le timeout (boucle infinie). */
  timeout?: boolean;
};

/** Langages exécutables côté client (Pyodide pour Python, eval contrôlé pour JS). */
export function executableLanguage(language: string): boolean {
  return (
    language === "python" || language === "javascript" || language === "js"
  );
}

type Pending = {
  resolve: (outcome: RunOutcome) => void;
  timer: ReturnType<typeof setTimeout>;
};

let worker: Worker | null = null;
let sequence = 0;
const pending = new Map<number, Pending>();

function rejectAll(reason: string) {
  for (const [, entry] of pending) {
    clearTimeout(entry.timer);
    entry.resolve({ ok: false, stdout: "", stderr: "", error: reason });
  }
  pending.clear();
}

function disposeWorker() {
  if (worker) {
    worker.terminate();
    worker = null;
  }
  rejectAll("interrupted");
}

function ensureWorker(): Worker {
  if (worker) return worker;
  worker = new Worker("/pyodide-worker.js");
  worker.onmessage = (event: MessageEvent) => {
    const { id, ...outcome } = event.data as RunOutcome & { id: number };
    const entry = pending.get(id);
    if (!entry) return;
    pending.delete(id);
    clearTimeout(entry.timer);
    entry.resolve(outcome);
  };
  worker.onerror = () => {
    disposeWorker();
  };
  return worker;
}

/**
 * Exécute `code` dans le worker, avec un timeout de sécurité : au-delà, le
 * worker est tué et recréé (une boucle infinie ne bloque jamais l'interface).
 * La première exécution inclut le téléchargement de Pyodide (~10 Mo).
 */
export function runCode(
  language: string,
  code: string,
  timeoutMs: number,
): Promise<RunOutcome> {
  return new Promise((resolve) => {
    const activeWorker = ensureWorker();
    const id = (sequence += 1);
    const timer = setTimeout(() => {
      pending.delete(id);
      disposeWorker();
      resolve({ ok: false, stdout: "", stderr: "", timeout: true });
    }, timeoutMs);
    pending.set(id, { resolve, timer });
    activeWorker.postMessage({ id, language, code });
  });
}
