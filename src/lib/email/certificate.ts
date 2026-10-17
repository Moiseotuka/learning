import { messages } from "@/i18n";
import { sendEmail } from "@/lib/email/send";

const t = messages.emails.certificate;

function formatDate(iso: string): string {
  return new Intl.DateTimeFormat("fr-FR", {
    day: "numeric",
    month: "long",
    year: "numeric",
  }).format(new Date(iso));
}

function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

export async function sendCertificateEmail(input: {
  to: string;
  name: string;
  title: string;
  code: string;
  issuedAt: string;
}): Promise<void> {
  const base = (process.env.NEXT_PUBLIC_SITE_URL && !/localhost|127\.0\.0\.1|0\.0\.0\.0/i.test(process.env.NEXT_PUBLIC_SITE_URL)
    ? process.env.NEXT_PUBLIC_SITE_URL
    : (process.env.VERCEL_PROJECT_PRODUCTION_URL ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}` : "https://elearning-three-phi.vercel.app"));
  const profileUrl = `${base}/app/profil`;
  const verifyUrl = `${base}/verifier?code=${encodeURIComponent(input.code)}`;
  const date = formatDate(input.issuedAt);

  const subject = t.subject(input.title);
  const text = [
    t.heading(input.name),
    "",
    t.body(input.title, date),
    "",
    `${t.cta} : ${profileUrl}`,
    `${t.verify} : ${verifyUrl}`,
    "",
    t.footer,
  ].join("\n");

  const html = `<!doctype html>
<html lang="fr">
<body style="margin:0;background:#f5f5f4;font-family:Helvetica,Arial,sans-serif;color:#111827">
  <div style="max-width:560px;margin:0 auto;padding:32px 20px">
    <div style="font-size:20px;font-weight:700;color:#15803d">easyTech</div>
    <div style="margin-top:20px;background:#ffffff;border:1px solid #e5e7eb;border-radius:16px;padding:28px">
      <h1 style="margin:0;font-size:22px">${escapeHtml(t.heading(input.name))}</h1>
      <p style="margin:14px 0 0;font-size:15px;line-height:1.6;color:#374151">${escapeHtml(t.body(input.title, date))}</p>
      <p style="margin:18px 0 0"><a href="${profileUrl}" style="display:inline-block;background:#15803d;color:#ffffff;text-decoration:none;border-radius:10px;padding:12px 20px;font-size:15px;font-weight:600">${escapeHtml(t.cta)}</a></p>
      <p style="margin:18px 0 0;font-size:13px;color:#6b7280">${escapeHtml(t.verify)} : <a href="${verifyUrl}" style="color:#15803d">${escapeHtml(input.code)}</a></p>
    </div>
    <p style="margin:18px 2px 0;font-size:12px;color:#9ca3af">${escapeHtml(t.footer)}</p>
  </div>
</body>
</html>`;

  await sendEmail({ to: input.to, subject, html, text });
}
