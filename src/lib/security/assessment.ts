import { createHmac, timingSafeEqual } from "node:crypto";

const ASSESSMENT_TTL_MS = 15 * 60 * 1000;

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
