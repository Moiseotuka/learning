import { createHmac, timingSafeEqual } from "node:crypto";

export const ASSESSMENT_TTL_MS = 15 * 60 * 1000;

/**
 * Date limite de validité encodée dans le jeton. La minuterie de l'examen s'y
 * cale plutôt que de repartir de zéro à l'hydratation : le temps a déjà couru
 * pendant le rendu serveur.
 */
export function assessmentDeadline(token: string): number {
  const value = Number(token.split(".")[0]);
  return Number.isFinite(value) ? value : Date.now() + ASSESSMENT_TTL_MS;
}

function resolveAssessmentSecret(): string {
  const secret =
    process.env.ASSESSMENT_SECRET ??
    process.env.SUPABASE_SERVICE_ROLE_KEY ??
    process.env.NEXT_PUBLIC_SUPABASE_URL ??
    "easylearn-assessment-dev-secret";

  return secret.trim();
}

function normalizeIds(ids: Iterable<string>): string[] {
  const seen = new Set<string>();
  const list: string[] = [];

  for (const rawId of ids) {
    const id = String(rawId).trim();
    if (!id || seen.has(id)) continue;
    seen.add(id);
    list.push(id);
  }

  return list;
}

function fnv1a(input: string): number {
  let hash = 0x811c9dc5;
  for (let i = 0; i < input.length; i += 1) {
    hash ^= input.charCodeAt(i);
    hash = Math.imul(hash, 0x01000193);
  }
  return hash >>> 0;
}

function mulberry32(seed: number): () => number {
  let state = seed >>> 0;
  return () => {
    state = (state + 0x6d2b79f5) >>> 0;
    let mixed = state;
    mixed = Math.imul(mixed ^ (mixed >>> 15), mixed | 1);
    mixed ^= mixed + Math.imul(mixed ^ (mixed >>> 7), mixed | 61);
    return ((mixed ^ (mixed >>> 14)) >>> 0) / 4294967296;
  };
}

/**
 * Tire le sujet d'examen de façon stable pour un même
 * (périmètre, apprenant, pool de questions). Un tirage aléatoire casserait
 * l'examen : tout ré-rendu changerait la sélection alors que le jeton signé
 * décrit la sélection précédente, et la vérification échouerait.
 * Le pool est trié avant d'entrer dans la graine : l'ordre renvoyé par la base
 * ne doit pas changer le sujet.
 */
export function drawExamQuestions<T extends { id: string }>(
  questions: readonly T[],
  scope: string,
  userId: string,
  count: number,
): T[] {
  if (count <= 0 || questions.length === 0) return [];

  const byId = (a: T, b: T) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0);
  const pool = [...questions].sort(byId);
  const random = mulberry32(
    fnv1a(`${scope}:${userId}:${pool.map((question) => question.id).join(",")}`),
  );

  for (let i = pool.length - 1; i > 0; i -= 1) {
    const j = Math.floor(random() * (i + 1));
    const current = pool[i] as T;
    pool[i] = pool[j] as T;
    pool[j] = current;
  }

  return pool.slice(0, Math.min(count, pool.length));
}

export function createAssessmentToken(
  scope: string,
  userId: string,
  questionIds: Iterable<string>,
): string {
  const ids = normalizeIds(questionIds);
  const expiresAt = Date.now() + ASSESSMENT_TTL_MS;
  const raw = `${scope}:${userId}:${expiresAt}:${ids.join(",")}`;
  const signature = createHmac("sha256", resolveAssessmentSecret())
    .update(raw)
    .digest("hex");
  const encoded = Buffer.from(raw).toString("base64url");
  return `${expiresAt}.${encoded}.${signature}`;
}

export function verifyAssessmentToken(
  token: string | null | undefined,
  scope: string,
  userId: string,
  questionIds: Iterable<string>,
): boolean {
  if (!token) return false;

  const parts = token.split(".");
  if (parts.length !== 3) return false;

  const [expiresAtString, encoded, providedSignature] = parts;
  const expiresAt = Number(expiresAtString);
  if (!Number.isFinite(expiresAt) || Date.now() > expiresAt) {
    return false;
  }

  const expectedIds = normalizeIds(questionIds);
  const raw = `${scope}:${userId}:${expiresAt}:${expectedIds.join(",")}`;
  const expectedSignature = createHmac("sha256", resolveAssessmentSecret())
    .update(raw)
    .digest("hex");

  try {
    const actual = Buffer.from(encoded, "base64url").toString("utf8");
    if (actual !== raw) {
      return false;
    }

    if (
      providedSignature.length !== expectedSignature.length ||
      !timingSafeEqual(
        Buffer.from(providedSignature),
        Buffer.from(expectedSignature),
      )
    ) {
      return false;
    }

    return true;
  } catch {
    return false;
  }
}
