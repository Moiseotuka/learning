import { CONTACT_EMAIL } from "@/config/contact";
import { createTransport, type Transporter } from "nodemailer";

type EmailInput = {
  to: string;
  subject: string;
  html: string;
  text: string;
};

export type EmailResult = { sent: boolean; demo: boolean; error?: string };

/**
 * Deux transporteurs, un seul contrat : la plateforme écrit « envoyez ce
 * message », et le premier fournisseur réellement configuré s'en charge.
 *
 * - SMTP (`SMTP_HOST` + `SMTP_USER` + `SMTP_PASS`) : le relais de l'équipe,
 *   Brevo, dont l'expéditeur est la boîte dépouillée par l'équipe. C'est le
 *   chemin de production, parce qu'il n'exige ni domaine à acheter ni clé à
 *   faire expirer.
 * - Resend (`RESEND_API_KEY`) : reste en secours, plus rapide par message.
 *
 * Sans configuration, l'envoi est tracé en log ([email:demo]) : le code est
 * prêt, seule la credential manque.
 */
export async function sendEmail(input: EmailInput): Promise<EmailResult> {
  const smtp = smtpSettings();
  if (smtp) return sendViaSmtp(smtp, input);
  return sendViaResend(input);
}

type SmtpSettings = {
  host: string;
  port: number;
  secure: boolean;
  user: string;
  pass: string;
  from: string;
};

function smtpSettings(): SmtpSettings | null {
  const host = process.env.SMTP_HOST?.trim();
  const user = process.env.SMTP_USER?.trim();
  const pass = process.env.SMTP_PASS?.trim();
  if (!host || !user || !pass) return null;

  const port = Number(process.env.SMTP_PORT ?? 465);
  const configured = process.env.SMTP_SECURE?.trim();
  return {
    host,
    port: Number.isFinite(port) && port > 0 ? port : 465,
    secure: configured ? configured !== "false" : port !== 587,
    user,
    pass,
    from: process.env.EMAIL_FROM?.trim() || `easyTech <${user}>`,
  };
}

let cachedTransport: { key: string; transport: Transporter } | null = null;

function smtpTransport(settings: SmtpSettings): Transporter {
  const key = `${settings.host}:${settings.port}:${settings.user}`;
  if (cachedTransport?.key === key) return cachedTransport.transport;

  const transport = createTransport({
    host: settings.host,
    port: settings.port,
    secure: settings.secure,
    auth: { user: settings.user, pass: settings.pass },
    // Une file courte : la route cron budgète ses envois, elle ne peut pas
    // rester bloquée sur un serveur SMTP qui ne répond pas.
    pool: true,
    maxConnections: 2,
    maxMessages: 4,
    connectionTimeout: 8_000,
    greetingTimeout: 8_000,
    socketTimeout: 15_000,
  });
  cachedTransport = { key, transport };
  return transport;
}

async function sendViaSmtp(
  settings: SmtpSettings,
  input: EmailInput,
): Promise<EmailResult> {
  try {
    await smtpTransport(settings).sendMail({
      from: settings.from,
      // Une réponse d'apprenant doit retomber dans la boîte de l'équipe.
      replyTo: CONTACT_EMAIL,
      to: input.to,
      subject: input.subject,
      html: input.html,
      text: input.text,
    });
    return { sent: true, demo: false };
  } catch (error) {
    // Le motif compte : la file de notifications le montre au formateur, qui
    // sinon ne voit qu'un « non remis » sans explication.
    const detail = error instanceof Error ? error.message : "smtp";
    console.error("[email] smtp", detail.slice(0, 180));
    return { sent: false, demo: false, error: detail.slice(0, 120) };
  }
}

async function sendViaResend(input: EmailInput): Promise<EmailResult> {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) {
    console.log(
      "[email:demo]",
      JSON.stringify({ to: input.to, subject: input.subject, text: input.text }),
    );
    return { sent: false, demo: true };
  }

  try {
    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: process.env.EMAIL_FROM ?? "easyTech <onboarding@resend.dev>",
        // L'adresse d'envoi est celle du domaine vérifié chez Resend ; la
        // réponse, elle, doit retomber dans la seule boîte dépouillée par
        // l'équipe. Sans ce champ, un apprenant qui répond perd son message.
        reply_to: CONTACT_EMAIL,
        to: [input.to],
        subject: input.subject,
        html: input.html,
        text: input.text,
      }),
    });

    if (!response.ok) {
      const detail = (await response.text()).slice(0, 180);
      console.error("[email] resend", response.status, detail);
      const message = detail.match(/"message":"([^"]+)"/)?.[1];
      return { sent: false, demo: false, error: message ?? `HTTP ${response.status}` };
    }

    return { sent: true, demo: false };
  } catch (error) {
    console.error("[email] resend", error);
    return {
      sent: false,
      demo: false,
      error: error instanceof Error ? error.message : "reseau",
    };
  }
}
