import { getUser } from "@/lib/auth/dal";
import { renderCertificatePdf } from "@/lib/certificates/pdf";
import { createServiceSupabase } from "@/lib/supabase/service";

export async function GET(
  _request: Request,
  ctx: { params: Promise<{ code: string }> },
) {
  const { code } = await ctx.params;

  const user = await getUser();
  if (!user) {
    return new Response("Unauthorized", { status: 401 });
  }

  const supabase = createServiceSupabase();
  if (!supabase) {
    return new Response("Not configured", { status: 503 });
  }

  const { data, error } = await supabase
    .from("certificates")
    .select("id,code,title,full_name,track_title,level,issued_at")
    .eq("code", code)
    .eq("user_id", user.id)
    .maybeSingle();

  if (error) {
    console.error("[certificates] pdf lookup", error.message);
    return new Response("Not found", { status: 404 });
  }
  if (!data) {
    return new Response("Not found", { status: 404 });
  }

  const pdf = await renderCertificatePdf({
    code: data.code,
    title: data.title,
    full_name: data.full_name,
  });

  const { searchParams } = new URL(_request.url);
  const headers = new Headers({
    "Content-Type": "application/pdf",
    "Cache-Control": "private, max-age=0, must-revalidate",
  });
  if (searchParams.get("inline") !== "1") {
    headers.set(
      "Content-Disposition",
      `attachment; filename="${data.code}.pdf"`,
    );
  }

  return new Response(pdf.slice().buffer, { headers });
}
