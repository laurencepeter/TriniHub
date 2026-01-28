import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  console.log("admin-create-user hit");

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey =
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    Deno.env.get("SUPABASE_SERVICE_KEY") ??
    Deno.env.get("SERVICE_SUPABASESERVICE_KEY");

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    console.error("Missing env vars", {
      hasSupabaseUrl: !!supabaseUrl,
      hasAnonKey: !!anonKey,
      hasServiceRoleKey: !!serviceRoleKey,
    });
    return new Response("Server missing env vars", { status: 500 });
  }

  const authHeader = req.headers.get("Authorization") ?? "";

  const supabaseUser = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const {
    data: { user },
    error: userErr,
  } = await supabaseUser.auth.getUser();
  if (userErr || !user) return new Response("Unauthorized", { status: 401 });

  const { data: profile } = await supabaseUser
    .from("user_profiles")
    .select("app_role")
    .eq("user_id", user.id)
    .single();

  if ((profile?.app_role ?? "") !== "admin") {
    return new Response("Forbidden", { status: 403 });
  }

  let body;
  try {
    body = await req.json();
  } catch {
    return new Response("Invalid JSON", { status: 400 });
  }

  const { email, temp_password, role, corporation_id, region_code } = body;

  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);

  const { data, error } = await supabaseAdmin.auth.admin.createUser({
    email,
    password: temp_password,
    email_confirm: true,
  });

  if (error) return new Response(JSON.stringify(error), { status: 400 });

  const { error: profErr } = await supabaseAdmin.from("user_profiles").upsert({
    user_id: data.user.id,
    app_role: role,
    corporation_id: corporation_id ?? null,
    region_code: region_code ?? null,
  });

  if (profErr) return new Response(JSON.stringify(profErr), { status: 400 });

  return new Response(JSON.stringify({ ok: true, user_id: data.user.id }), {
    status: 200,
  });
});
