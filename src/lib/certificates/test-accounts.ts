/**
 * Comptes autorisés à utiliser le bouton « certificat de test » de la page
 * Profil. Strictement réservé au mode développement : la liste est
 * configurable via CERTIFICATE_TEST_ACCOUNTS dans .env.local.
 */
export function isCertificateTestAccount(email: string | null | undefined): boolean {
  if (process.env.NODE_ENV !== "development") return false;
  if (!email) return false;
  const list = (
    process.env.CERTIFICATE_TEST_ACCOUNTS ??
    "quiz-test@easylearn.dev,demo@easylearn.app"
  )
    .split(",")
    .map((item) => item.trim().toLowerCase())
    .filter(Boolean);
  return list.includes(email.toLowerCase());
}
