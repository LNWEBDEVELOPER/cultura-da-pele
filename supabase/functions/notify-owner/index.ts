import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type", "Access-Control-Allow-Methods": "POST, OPTIONS" };
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return Response.json({ error: "Method not allowed" }, { status: 405, headers: cors });
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) return Response.json({ error: "Sign in required" }, { status: 401, headers: cors });
    const url = Deno.env.get("SUPABASE_URL")!;
    const anon = Deno.env.get("SUPABASE_ANON_KEY")!;
    const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const userClient = createClient(url, anon, { global: { headers: { Authorization: authHeader } }, auth: { autoRefreshToken: false, persistSession: false } });
    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user?.email || !user.email_confirmed_at) return Response.json({ error: "Verified account required" }, { status: 401, headers: cors });
    const ownerEmail = Deno.env.get("OWNER_EMAIL");
    const apiKey = Deno.env.get("RESEND_API_KEY");
    const fromEmail = Deno.env.get("NOTIFICATION_FROM_EMAIL");
    if (!apiKey || !ownerEmail || !fromEmail) throw new Error("Email secrets are not configured");
    const admin = createClient(url, service, { auth: { autoRefreshToken: false, persistSession: false } });
    const { data: profile, error } = await admin.from("profiles").select("id,email,approval_status,notified_at").eq("id", user.id).maybeSingle();
    if (error || !profile || profile.approval_status !== "pending" || profile.notified_at) return Response.json({ ok: true }, { headers: cors });
    const { data: claimed, error: claimError } = await admin.from("profiles").update({ notified_at: new Date().toISOString() }).eq("id", user.id).is("notified_at", null).select("id").maybeSingle();
    if (claimError) throw claimError;
    if (!claimed) return Response.json({ ok: true }, { headers: cors });
    const response = await fetch("https://api.resend.com/emails", {
      method: "POST", headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({ from: fromEmail, to: [ownerEmail], subject: "Pedido de acesso ao Cultura da Pele", text: `Um novo pedido de acesso foi confirmado para ${profile.email}.\n\nAbra ${Deno.env.get("SITE_URL") || "https://lnwebdeveloper.github.io/cultura-da-pele/"}#area-estudio e entre com sua conta proprietária para aprovar ou recusar.\n\nA senha nunca é enviada por e-mail.` }),
    });
    if (!response.ok) {
      await admin.from("profiles").update({ notified_at: null }).eq("id", user.id);
      throw new Error(`Email provider returned ${response.status}`);
    }
    return Response.json({ ok: true }, { headers: cors });
  } catch (error) {
    console.error(error);
    return Response.json({ error: "Could not notify owner" }, { status: 500, headers: cors });
  }
});

