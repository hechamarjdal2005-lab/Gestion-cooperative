import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  // 0. Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type' } })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'No authorization header' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      })
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Verify the user is an admin
    const supabaseUser = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: userError } = await supabaseUser.auth.getUser()
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Invalid token' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      })
    }

    const { data: profile } = await supabaseAdmin.from("profiles").select("role").eq("id", user.id).single()
    if (profile?.role !== 'admin') {
      return new Response(JSON.stringify({ error: 'Unauthorized: Admin only' }), {
        status: 403,
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      })
    }

    // قرا البيانات اللي صيفطها الأدمن
    const { email, password, fullName } = await req.json();
...
    // 1. خلق المستخدم (Email & Password)
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true, // تأكيد الايميل أوتوماتيك
    });

    if (authError) throw authError;
    const userId = authData.user.id;

    // 2. خلق البروفايل (بدون تعاونية حالياً)
    // cooperative_id خليه null باش التطبيق يعرف أنه خاصو يعمرو
    const { error: profileError } = await supabaseAdmin.from("profiles").insert({
      id: userId,
      full_name: fullName,
      email: email,
      role: "admin_cooperative",
      cooperative_id: null, 
      must_change_password: true, // مهم جداً
    });

    if (profileError) throw profileError;

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { "Content-Type": "application/json", 'Access-Control-Allow-Origin': '*' },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      status: 400,
      headers: { "Content-Type": "application/json", 'Access-Control-Allow-Origin': '*' },
    });
  }
});