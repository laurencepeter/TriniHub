import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  console.log("admin-create-user hit");
  console.log("AUTH HEADER:", req.headers.get("Authorization"));

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
    db: { schema: "trinihub" },
    global: { headers: { Authorization: authHeader } },
  });

  const { data: userData, error: userErr } =
    await supabaseUser.auth.getUser();
  if (userErr || !userData?.user) {
    return new Response("Unauthorized", { status: 401 });
  }

  const { data: profile, error: profErr } = await supabaseUser
    .from("user_profiles")
    .select("role, app_role")
    .eq("user_id", userData.user.id)
    .single();

  if (profErr) return new Response(JSON.stringify(profErr), { status: 400 });

  const effectiveRole = String(profile?.role ?? profile?.app_role ?? "");
  if (effectiveRole !== "admin") {
    return new Response("Forbidden", { status: 403 });
  }

  let body;
  try {
    body = await req.json();
  } catch {
    return new Response("Invalid JSON", { status: 400 });
  }

  const {
    email,
    temp_password,
    role,
    corporation_id,
    organization,
    region_code,
    display_name,
  } = body;
  const normalizeText = (value: unknown) =>
    (value ?? "").toString().trim();
  const isUuid = (value: string) =>
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
      value,
    );

  const normalizeRole = (value: string | undefined | null) => {
    const raw = (value ?? "").toString().trim().toLowerCase();
    if (raw === "public") return "public_user";
    if (raw === "corp") return "corporation";
    if (raw === "corp_staff" || raw === "staff") return "corp_staff";
    if (raw === "administrator") return "admin";
    return raw;
  };

  const normalizedRole = normalizeRole(role);
  const allowedRoles = new Set([
    "admin",
    "corporation",
    "corp_staff",
    "public_user",
  ]);
  if (!allowedRoles.has(normalizedRole)) {
    return new Response("Invalid role.", { status: 400 });
  }

  const rawCorporationId = normalizeText(corporation_id);
  const rawOrganization = normalizeText(organization);
  let corporationId = rawCorporationId || null;
  let corporationName = rawOrganization || null;

  if (corporationId && !isUuid(corporationId) && !corporationName) {
    corporationName = corporationId;
    corporationId = null;
  }

  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
    db: { schema: "trinihub" },
  });

  if (!corporationId && corporationName) {
    const { data: region, error: regionError } = await supabaseAdmin
      .from("corporations")
      .select("id,name")
      .ilike("name", corporationName)
      .limit(1)
      .maybeSingle();
    if (!regionError && region) {
      corporationId = region.id;
      corporationName = region.name;
    }
  }

  if (corporationId && !corporationName) {
    const { data: region, error: regionError } = await supabaseAdmin
      .from("corporations")
      .select("id,name")
      .eq("id", corporationId)
      .maybeSingle();
    if (!regionError && region) {
      corporationName = region.name;
    }
  }

  if (
    ["corporation", "corp_staff"].includes(normalizedRole) &&
    !corporationId &&
    !corporationName
  ) {
    return new Response(
      "Corporation name is required for staff accounts.",
      {
        status: 400,
      },
    );
  }

  const { data, error } = await supabaseAdmin.auth.admin.createUser({
    email,
    password: temp_password,
    email_confirm: true,
  });

  if (error) return new Response(JSON.stringify(error), { status: 400 });

  const metadata = {
    app_role: normalizedRole,
    role: normalizedRole,
    ...(corporationId ? { corporation_id: corporationId } : {}),
  };
  const { error: metadataErr } =
    await supabaseAdmin.auth.admin.updateUserById(data.user.id, {
      app_metadata: metadata,
    });
  if (metadataErr) {
    console.warn("Unable to set app metadata", metadataErr);
  }

  const { error: profErr } = await supabaseAdmin.from("user_profiles").upsert({
    user_id: data.user.id,
    role: normalizedRole,
    app_role: normalizedRole,
    corporation_id: corporationId,
    organization: corporationName,
    region_code: region_code ?? null,
    display_name: display_name ?? null,
  });

  if (profErr) return new Response(JSON.stringify(profErr), { status: 400 });

  return new Response(JSON.stringify({ ok: true, user_id: data.user.id }), {
    status: 200,
  });
});
