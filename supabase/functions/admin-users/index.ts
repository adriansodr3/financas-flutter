import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

const ADMIN_EMAIL = "adriansodre1@gmail.com"

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Não autorizado" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" }
      })
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!
    const serviceKey  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    const anonKey     = Deno.env.get("SUPABASE_ANON_KEY")!

    // Verificar se o usuário é admin
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } }
    })
    const { data: { user }, error: userError } = await userClient.auth.getUser()
    if (userError || !user || user.email !== ADMIN_EMAIL) {
      return new Response(JSON.stringify({ error: "Acesso negado" }), {
        status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" }
      })
    }

    const adminClient = createClient(supabaseUrl, serviceKey)
    const { action, userId, email } = await req.json()

    // ── LIST USERS ──────────────────────────────────────────
    if (action === "list") {
      const { data, error } = await adminClient.auth.admin.listUsers()
      if (error) throw error
      return new Response(JSON.stringify({ users: data.users }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      })
    }

    // ── DB STATS ────────────────────────────────────────────
    if (action === "db-stats") {
      // Tamanho de cada tabela do app
      const tables = ["categories", "transactions", "fixed_expenses", "fixed_skipped", "installments", "investments"]
      const tableStats = []
      let totalBytes = 0

      for (const table of tables) {
        const { data, error } = await adminClient.rpc("table_size", { table_name: table })
        if (!error && data) {
          tableStats.push({ table, bytes: data })
          totalBytes += data as number
        }
      }

      // Contar registros por tabela
      const counts: Record<string, number> = {}
      for (const table of tables) {
        const { count } = await adminClient.from(table).select("*", { count: "exact", head: true })
        counts[table] = count ?? 0
      }

      // Plano free do Supabase: 500MB = 524288000 bytes
      const LIMIT_BYTES = 500 * 1024 * 1024

      return new Response(JSON.stringify({
        total_bytes: totalBytes,
        limit_bytes: LIMIT_BYTES,
        percent_used: ((totalBytes / LIMIT_BYTES) * 100).toFixed(2),
        tables: tableStats,
        counts,
      }), { headers: { ...corsHeaders, "Content-Type": "application/json" } })
    }

    // ── RESET PASSWORD ──────────────────────────────────────
    if (action === "reset-password") {
      await adminClient.auth.admin.generateLink({ type: "recovery", email })
      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      })
    }

    // ── DELETE USER ─────────────────────────────────────────
    if (action === "delete") {
      // 1. Revogar TODAS as sessões ativas do usuário em todos os dispositivos
      await adminClient.auth.admin.signOut(userId, 'global')
      // 2. Deletar o usuário (invalida permanentemente todos os tokens)
      const { error } = await adminClient.auth.admin.deleteUser(userId)
      if (error) throw error
      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      })
    }

    // ── INVITE USER ─────────────────────────────────────────
    if (action === "invite") {
      const { error } = await adminClient.auth.admin.inviteUserByEmail(email)
      if (error) throw error
      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      })
    }

    // ── PENDING USERS ────────────────────────────────────────
    if (action === "pending-users") {
      const { data, error } = await adminClient
        .from('user_profiles')
        .select('*')
        .eq('status', 'pending')
        .order('created_at', { ascending: false })
      if (error) throw error
      return new Response(JSON.stringify({ users: data }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      })
    }

    // ── APPROVE USER ─────────────────────────────────────────
    if (action === "approve") {
      const { error } = await adminClient
        .from('user_profiles')
        .update({ status: 'approved', approved_at: new Date().toISOString() })
        .eq('id', userId)
      if (error) throw error
      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      })
    }

    // ── REJECT USER ──────────────────────────────────────────
    if (action === "reject") {
      // Rejeitar: deletar o usuário completamente
      await adminClient.auth.admin.signOut(userId, 'global')
      const { error } = await adminClient.auth.admin.deleteUser(userId)
      if (error) throw error
      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      })
    }

    return new Response(JSON.stringify({ error: "Ação inválida" }), {
      status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" }
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" }
    })
  }
})
