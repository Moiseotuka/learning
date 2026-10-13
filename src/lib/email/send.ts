type EmailInput = {
  to: string;
  subject: string;
  html: string;
  text: string;
};

export type EmailResult = { sent: boolean; demo: boolean; error?: string };

/**
 * Envoi via Resend. Sans RESEND_API_KEY, l'email est tracé en log
 * ([email:demo]) : le code reste prêt, seule la clé manque.
 */
export async function sendEmail(input: EmailInput): Promise<EmailResult> {
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
        to: [input.to],
        subject: input.subject,
        html: input.html,
        text: input.text,
      }),
    });

    if (!response.ok) {
      // Le motif de Refuser compte : la file de notifications le montre au
      // formateur, qui sinon ne voit qu'un « non remis » sans explication.
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
