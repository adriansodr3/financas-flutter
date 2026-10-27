import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl  = Deno.env.get('SUPABASE_URL')!
const supabaseKey  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const vapidPub     = Deno.env.get('VAPID_PUBLIC_KEY')!
const vapidPriv    = Deno.env.get('VAPID_PRIVATE_KEY')!
const vapidEmail   = Deno.env.get('VAPID_EMAIL') ?? 'mailto:admin@financas.app'

// ── VAPID / Web Push helpers ──────────────────────────────────────────────────

function urlBase64ToUint8Array(base64String: string): Uint8Array {
  const padding = '='.repeat((4 - (base64String.length % 4)) % 4)
  const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/')
  const raw = atob(base64)
  return Uint8Array.from([...raw].map(c => c.charCodeAt(0)))
}

async function importVapidKey(b64: string, usage: KeyUsage[]): Promise<CryptoKey> {
  return crypto.subtle.importKey(
    'raw',
    urlBase64ToUint8Array(b64),
    { name: 'ECDH', namedCurve: 'P-256' },
    false,
    usage,
  )
}

async function importVapidPrivate(b64: string): Promise<CryptoKey> {
  const raw = urlBase64ToUint8Array(b64)
  // VAPID private keys are 32-byte raw scalars; wrap in PKCS8 for SubtleCrypto
  const pkcs8 = new Uint8Array([
    0x30, 0x41, 0x02, 0x01, 0x00, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48,
    0xce, 0x3d, 0x02, 0x01, 0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03,
    0x01, 0x07, 0x04, 0x27, 0x30, 0x25, 0x02, 0x01, 0x01, 0x04, 0x20,
    ...raw,
  ])
  return crypto.subtle.importKey('pkcs8', pkcs8, { name: 'ECDSA', namedCurve: 'P-256' }, false, ['sign'])
}

async function buildVapidToken(audience: string): Promise<string> {
  const exp = Math.floor(Date.now() / 1000) + 12 * 3600
  const header = btoa(JSON.stringify({ typ: 'JWT', alg: 'ES256' }))
    .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
  const payload = btoa(JSON.stringify({ aud: audience, exp, sub: vapidEmail }))
    .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
  const sigInput = new TextEncoder().encode(`${header}.${payload}`)
  const privKey = await importVapidPrivate(vapidPriv)
  const sig = await crypto.subtle.sign({ name: 'ECDSA', hash: 'SHA-256' }, privKey, sigInput)
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
  return `vapid t=${header}.${payload}.${sigB64},k=${vapidPub}`
}

async function encryptPayload(
  payload: string,
  userPublicKeyB64: string,
  authB64: string,
): Promise<{ body: Uint8Array; salt: string; serverPublicKey: string }> {
  const userPublicKey = await importVapidKey(userPublicKeyB64, [])
  const serverKey = await crypto.subtle.generateKey({ name: 'ECDH', namedCurve: 'P-256' }, true, ['deriveKey', 'deriveBits'])
  const serverPublicKeyRaw = await crypto.subtle.exportKey('raw', serverKey.publicKey)
  const serverPublicKeyB64 = btoa(String.fromCharCode(...new Uint8Array(serverPublicKeyRaw)))
    .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')

  const sharedSecret = await crypto.subtle.deriveBits(
    { name: 'ECDH', public: userPublicKey }, serverKey.privateKey, 256)
  const authBytes = urlBase64ToUint8Array(authB64)
  const salt = crypto.getRandomValues(new Uint8Array(16))

  // HKDF PRK
  const prkKey = await crypto.subtle.importKey('raw', sharedSecret, { name: 'HKDF' }, false, ['deriveKey', 'deriveBits'])
  const authInfo = new TextEncoder().encode('Content-Encoding: auth\0')
  const prk = await crypto.subtle.deriveBits(
    { name: 'HKDF', hash: 'SHA-256', salt: authBytes, info: authInfo }, prkKey, 256)

  // CEK & nonce
  const serverPubRaw = new Uint8Array(serverPublicKeyRaw)
  const userPubRaw = urlBase64ToUint8Array(userPublicKeyB64)
  const keyInfo = new Uint8Array([
    ...new TextEncoder().encode('Content-Encoding: aesgcm\0'),
    0x00, 0x41, ...serverPubRaw,
    0x00, 0x41, ...userPubRaw,
  ])
  const nonceInfo = new Uint8Array([
    ...new TextEncoder().encode('Content-Encoding: nonce\0'),
    0x00, 0x41, ...serverPubRaw,
    0x00, 0x41, ...userPubRaw,
  ])
  const prkKey2 = await crypto.subtle.importKey('raw', prk, { name: 'HKDF' }, false, ['deriveBits'])
  const cek = await crypto.subtle.deriveBits({ name: 'HKDF', hash: 'SHA-256', salt, info: keyInfo }, prkKey2, 128)
  const nonce = await crypto.subtle.deriveBits({ name: 'HKDF', hash: 'SHA-256', salt, info: nonceInfo }, prkKey2, 96)

  const aesKey = await crypto.subtle.importKey('raw', cek, { name: 'AES-GCM' }, false, ['encrypt'])
  const payloadBytes = new TextEncoder().encode(payload)
  const padded = new Uint8Array([0, 0, ...payloadBytes]) // 2-byte padding length
  const encrypted = await crypto.subtle.encrypt({ name: 'AES-GCM', iv: nonce }, aesKey, padded)

  return {
    body: new Uint8Array(encrypted),
    salt: btoa(String.fromCharCode(...salt)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_'),
    serverPublicKey: serverPublicKeyB64,
  }
}

async function sendPush(sub: { endpoint: string; p256dh: string; auth: string }, payload: string) {
  const url = new URL(sub.endpoint)
  const audience = `${url.protocol}//${url.host}`
  const vapidToken = await buildVapidToken(audience)
  const { body, salt, serverPublicKey } = await encryptPayload(payload, sub.p256dh, sub.auth)

  const res = await fetch(sub.endpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/octet-stream',
      'Content-Encoding': 'aesgcm',
      'Authorization': vapidToken,
      'Encryption': `salt=${salt}`,
      'Crypto-Key': `dh=${serverPublicKey}`,
      'TTL': '86400',
    },
    body,
  })
  return res.status
}

// ── BRL formatter ─────────────────────────────────────────────────────────────

function brl(amount: number): string {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(amount)
}

// ── Main handler ──────────────────────────────────────────────────────────────

Deno.serve(async (_req) => {
  const supabase = createClient(supabaseUrl, supabaseKey)

  const today = new Date()
  const todayDay = today.getDate()
  const ALERT_DAYS = [0, 1, 3, 7]

  // Busca todas as despesas fixas ativas com due_day
  const { data: expenses, error: expErr } = await supabase
    .from('fixed_expenses')
    .select('user_id, description, due_day, amount')
    .eq('active', true)
    .not('due_day', 'is', null)
    .eq('type', 'expense')

  if (expErr || !expenses?.length) {
    return new Response(JSON.stringify({ ok: true, sent: 0 }), { status: 200 })
  }

  // Agrupa alertas por usuário
  const byUser: Record<string, Array<{ description: string; dueDay: number; amount: number; daysUntil: number }>> = {}
  for (const exp of expenses) {
    const daysUntil = (exp.due_day as number) - todayDay
    if (!ALERT_DAYS.includes(daysUntil)) continue
    if (!byUser[exp.user_id]) byUser[exp.user_id] = []
    byUser[exp.user_id].push({ description: exp.description, dueDay: exp.due_day, amount: exp.amount, daysUntil })
  }

  const userIds = Object.keys(byUser)
  if (!userIds.length) return new Response(JSON.stringify({ ok: true, sent: 0 }), { status: 200 })

  // Busca subscriptions dos usuários com alertas
  const { data: subs } = await supabase
    .from('push_subscriptions')
    .select('user_id, endpoint, p256dh, auth')
    .in('user_id', userIds)

  if (!subs?.length) return new Response(JSON.stringify({ ok: true, sent: 0 }), { status: 200 })

  let sent = 0
  const expired: string[] = []

  for (const sub of subs) {
    const alerts = byUser[sub.user_id] ?? []
    for (const alert of alerts) {
      const daysText =
        alert.daysUntil === 0 ? 'Vence hoje!' :
        alert.daysUntil === 1 ? 'Vence amanhã' :
        `Vence em ${alert.daysUntil} dias`

      const payload = JSON.stringify({
        title: `⚠️ ${alert.description}`,
        body: `${daysText} • ${brl(alert.amount)}`,
        tag: `due-${sub.user_id}-${alert.dueDay}`,
      })

      try {
        const status = await sendPush(sub, payload)
        if (status === 410 || status === 404) {
          expired.push(sub.endpoint)
        } else {
          sent++
        }
      } catch (_) { /* ignora erros de rede pontuais */ }
    }
  }

  // Remove subscriptions expiradas
  if (expired.length) {
    await supabase.from('push_subscriptions').delete().in('endpoint', expired)
  }

  return new Response(JSON.stringify({ ok: true, sent, expired: expired.length }), { status: 200 })
})
