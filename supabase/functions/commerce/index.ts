const providerUrl = 'https://plopplop.solutionip.app/';
const encoder = new TextEncoder();
type Data = Record<string, any>;

class ApiError extends Error {
  constructor(public code: string, public status = 400) { super(code); }
}

function secret(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new ApiError('SERVER_NOT_CONFIGURED', 503);
  return value;
}

export async function hmac(payload: string, key: string): Promise<string> {
  const cryptoKey = await crypto.subtle.importKey('raw', encoder.encode(key), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const bytes = new Uint8Array(await crypto.subtle.sign('HMAC', cryptoKey, encoder.encode(payload)));
  return Array.from(bytes, b => b.toString(16).padStart(2, '0')).join('');
}

export async function validSignature(raw: string, signature: string, key: string): Promise<boolean> {
  if (!/^sha256=[a-f0-9]{64}$/.test(signature)) return false;
  const bytes = Uint8Array.from(signature.slice(7).match(/../g)!, x => parseInt(x, 16));
  const cryptoKey = await crypto.subtle.importKey('raw', encoder.encode(key), { name: 'HMAC', hash: 'SHA-256' }, false, ['verify']);
  return crypto.subtle.verify('HMAC', cryptoKey, bytes, encoder.encode(raw));
}

export function withdrawalPayload(amount: number, method: string, recipient: string, reference: string, timestamp: number): string {
  if (!Number.isFinite(amount) || amount <= 0 || Math.abs(amount * 100 - Math.round(amount * 100)) > 0.000001 || !['moncash', 'natcash'].includes(method) || !/^509\d{8}$/.test(recipient) || !/^[a-zA-Z0-9-]{1,100}$/.test(reference) || !Number.isSafeInteger(timestamp)) throw new ApiError('INVALID_WITHDRAWAL');
  return [amount, method, recipient, reference, timestamp].join('|');
}

export function paymentUrl(value: unknown): string | null {
  if (value == null) return null;
  if (typeof value !== 'string') throw new ApiError('INVALID_PROVIDER_RESPONSE', 502);
  const url = new URL(value);
  if (url.protocol !== 'https:' || url.username || url.password) throw new ApiError('INVALID_PROVIDER_RESPONSE', 502);
  return url.toString();
}

async function database(path: string, method = 'GET', body?: Data | Data[], jwt?: string): Promise<any> {
  const key = secret('SUPABASE_SERVICE_ROLE_KEY');
  const response = await fetch(`${secret('SUPABASE_URL')}/rest/v1/${path}`, {
    method,
    headers: { apikey: key, Authorization: `Bearer ${jwt ?? key}`, 'Content-Type': 'application/json', Prefer: 'return=representation' },
    body: body === undefined ? undefined : JSON.stringify(body),
    signal: AbortSignal.timeout(15000), redirect: 'error',
  });
  if (!response.ok) {
    const error = await response.json().catch(() => ({}));
    const allowed = ['WITHDRAWAL_COOLDOWN', 'payment_mismatch'];
    throw new ApiError(allowed.includes(error.message) ? error.message : 'DATABASE_ERROR', 409);
  }
  const text = await response.text();
  return text ? JSON.parse(text) : null;
}

async function provider(path: string, body: Data, token?: string): Promise<Data> {
  let response: Response;
  try {
    response = await fetch(`${providerUrl}${path}`, {
      method: 'POST', redirect: 'error',
      headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
      body: JSON.stringify(body), signal: AbortSignal.timeout(20000),
    });
  } catch { throw new ApiError('PROVIDER_OUTCOME_UNKNOWN', 503); }
  const data = await response.json().catch(() => { throw new ApiError('PROVIDER_OUTCOME_UNKNOWN', 502); });
  if (!response.ok || (data.status !== true && data.success !== true)) {
    const codes = ['INSUFFICIENT_BALANCE','TOKEN_ALREADY_USED','API_TRANSFER_FAILED','DUPLICATE_REFERENCE','WITHDRAWAL_COOLDOWN','METHOD_NOT_CONFIGURED','INVALID_SIGNATURE','TIMESTAMP_EXPIRED','NO_CLIENT_SECRET','PARAMETER_MISMATCH','INVALID_TOKEN_TYPE'];
    throw new ApiError(codes.includes(data.error_code) ? data.error_code : `PROVIDER_HTTP_${response.status}`, response.status >= 400 ? response.status : 502);
  }
  return data;
}

async function authenticate(request: Request): Promise<{ user: Data; jwt: string }> {
  const jwt = request.headers.get('Authorization')?.replace(/^Bearer /, '');
  if (!jwt) throw new ApiError('AUTHENTICATION_REQUIRED', 401);
  const response = await fetch(`${secret('SUPABASE_URL')}/auth/v1/user`, {
    headers: { apikey: secret('SUPABASE_SERVICE_ROLE_KEY'), Authorization: `Bearer ${jwt}` }, signal: AbortSignal.timeout(10000), redirect: 'error',
  });
  if (!response.ok) throw new ApiError('AUTHENTICATION_REQUIRED', 401);
  const user = await response.json();
  if (user.is_anonymous) throw new ApiError('AUTHENTICATION_REQUIRED', 401);
  return { user, jwt };
}

function uuid(value: unknown): string {
  if (typeof value !== 'string' || !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value)) throw new ApiError('INVALID_ID');
  return value;
}

async function ownedOrder(id: unknown, user: Data): Promise<Data> {
  const rows = await database(`orders?id=eq.${uuid(id)}&user_id=eq.${uuid(user.id)}&select=*`);
  if (!rows.length) throw new ApiError('ORDER_NOT_FOUND', 404);
  return rows[0];
}

async function verifyPayment(payment: Data): Promise<Data> {
  const verified = await provider('api/paiement-verify', {
    client_id: secret('PLOP_CLIENT_ID'), refference_id: payment.reference,
  });
  const methods = ['moncash', 'moncash_ussd', 'natcash', 'kashpaw', 'carte'];
  if (!['ok', 'no'].includes(verified.trans_status) || !verified.id_transaction || Number(verified.montant) !== Number(payment.amount) || (payment.transaction_id && String(verified.id_transaction) !== payment.transaction_id) || (verified.method != null && !methods.includes(verified.method))) throw new ApiError('PAYMENT_MISMATCH', 409);
  await database('rpc/apply_payment', 'POST', {
    p_reference: payment.reference, p_transaction: String(verified.id_transaction), p_amount: Number(verified.montant), p_paid: verified.trans_status === 'ok',
  });
  return (await database(`payments?order_id=eq.${payment.order_id}&select=*`))[0];
}

async function merchantToken(): Promise<string> {
  const result = await provider('api/auth/marchand', { client_id: secret('PLOP_CLIENT_ID'), client_secret: secret('PLOP_CLIENT_SECRET') });
  if (typeof result.token !== 'string' || !result.token) throw new ApiError('INVALID_PROVIDER_RESPONSE', 502);
  return result.token;
}

async function processRequest(request: Request, data: Data, raw: string): Promise<Data> {
  if (data.action === 'webhook' || data.event) {
    if (!await validSignature(raw, request.headers.get('X-Webhook-Signature') ?? '', secret('PLOP_CLIENT_SECRET'))) throw new ApiError('INVALID_SIGNATURE', 401);
    if (!['transaction.created', 'transaction.status_changed'].includes(data.event) || data.merchant?.client_id !== secret('PLOP_CLIENT_ID')) throw new ApiError('INVALID_WEBHOOK');
    const reference = data.transaction?.reference_id;
    if (typeof reference !== 'string' || !/^PAY-[0-9a-f-]{36}$/i.test(reference)) throw new ApiError('INVALID_REFERENCE');
    const payments = await database(`payments?reference=eq.${encodeURIComponent(reference)}&select=*`);
    if (!payments.length) throw new ApiError('PAYMENT_NOT_FOUND', 404);
    await verifyPayment(payments[0]);
    return { received: true };
  }

  const { user, jwt } = await authenticate(request);
  if (data.action === 'payment.start' || data.action === 'payment.verify') {
    const order = await ownedOrder(data.order_id, user);
    const payments = await database(`payments?order_id=eq.${order.id}&select=*`);
    if (data.action === 'payment.verify') {
      if (!payments.length) throw new ApiError('PAYMENT_NOT_FOUND', 404);
      return await verifyPayment(payments[0]);
    }
    if (payments.length) {
      const existing = payments[0];
      if (existing.status !== 'creating') return existing;
      // Yon ansyen apèl ka tonbe apre founisè a te kreye tranzaksyon an.
      // Verifye anvan: si founisè a pa jwenn referans lan (404 / status:false /
      // paramètre invalide), efase liy 'creating' la epi rekòmanse. Erè rezo
      // (OUTCOME_UNKNOWN) pa jere isit — li pwopaje pou itilizatè a eseye ankò.
      try { return await verifyPayment(existing); }
      catch (error) {
        const notFound = error instanceof ApiError && ['PROVIDER_HTTP_400', 'PROVIDER_HTTP_404', 'PROVIDER_HTTP_502'].includes(error.code);
        if (!notFound) throw error;
        await database(`payments?order_id=eq.${order.id}&status=eq.creating`, 'DELETE');
      }
    }
    if (order.status !== 'pending') throw new ApiError('INVALID_ORDER_STATE', 409);
    const methods = await database(`payment_methods?code=eq.${encodeURIComponent(order.payment_method)}&enabled=eq.true&select=code`);
    if (!methods.length) throw new ApiError('PAYMENT_METHOD_DISABLED');
    if (order.payment_method === 'moncash_ussd' && !/^509\d{8}$/.test(data.phone_number ?? '')) throw new ApiError('INVALID_PHONE');
    secret('PLOP_CLIENT_ID');
    const claimed = await database('rpc/claim_payment', 'POST', { p_order_id: order.id });
    if (!claimed) throw new ApiError('PAYMENT_ALREADY_STARTED', 409);
    const reference = `PAY-${order.id}`;
    let result: Data;
    try {
      result = await provider('api/paiement-marchand', {
        client_id: secret('PLOP_CLIENT_ID'), refference_id: reference,
        montant: Number(order.total), payment_method: order.payment_method,
        ...(order.payment_method === 'moncash_ussd' ? { phone_number: data.phone_number } : {}),
      });
    } catch (error) {
      // Si referans lan deja egziste bò founisè a (repons pèdi), verifye li olye.
      if (error instanceof ApiError && ['PROVIDER_HTTP_404', 'DUPLICATE_REFERENCE'].includes(error.code)) {
        return await verifyPayment((await database(`payments?order_id=eq.${order.id}&select=*`))[0]);
      }
      throw error;
    }
    if (!result.transaction_id) throw new ApiError('PROVIDER_OUTCOME_UNKNOWN', 502);
    const url = paymentUrl(result.url);
    if (order.payment_method !== 'moncash_ussd' && !url) throw new ApiError('PROVIDER_OUTCOME_UNKNOWN', 502);
    // Patch la a aplike sèlman si peman an toujou 'creating' — yon webhook ki gentan
    // make li 'paid'/'review' pa dwe ekrase.
    const patched = await database(`payments?order_id=eq.${order.id}&status=eq.creating`, 'PATCH', { transaction_id: String(result.transaction_id), redirect_url: url, status: 'pending' });
    const final = patched.length ? patched[0] : (await database(`payments?order_id=eq.${order.id}&select=*`))[0];
    if (!final || !['pending', 'paid', 'review'].includes(final.status)) throw new ApiError('PROVIDER_OUTCOME_UNKNOWN', 503);
    return final;
  }

  if (data.action === 'account.delete') {
    if (data.confirmation !== 'DELETE') throw new ApiError('CONFIRMATION_REQUIRED');
    const segment = jwt.split('.')[1].replace(/-/g, '+').replace(/_/g, '/');
    const claims = JSON.parse(atob(segment.padEnd(Math.ceil(segment.length / 4) * 4, '=')));
    const recent = (claims.amr ?? []).some((entry: Data) => ['password', 'oauth'].includes(entry.method) && entry.timestamp > Date.now() / 1000 - 600);
    if (!recent) throw new ApiError('REAUTHENTICATION_REQUIRED', 401);
    const active = await database(`orders?user_id=eq.${uuid(user.id)}&or=(status.not.in.(delivered,cancelled),payment_status.eq.review)&select=id&limit=1`);
    if (active.length) throw new ApiError('ACTIVE_ORDERS', 409);
    if (await database('rpc/is_admin', 'POST', {}, jwt)) throw new ApiError('ADMIN_DELETION_REQUIRES_TRANSFER', 409);
    const key = secret('SUPABASE_SERVICE_ROLE_KEY');
    const response = await fetch(`${secret('SUPABASE_URL')}/auth/v1/admin/users/${uuid(user.id)}`, {
      method: 'DELETE', headers: { apikey: key, Authorization: `Bearer ${key}` }, signal: AbortSignal.timeout(15000), redirect: 'error',
    });
    if (!response.ok) throw new ApiError('ACCOUNT_DELETION_FAILED', 409);
    return { deleted: true };
  }

  if (!await database('rpc/is_admin', 'POST', {}, jwt)) throw new ApiError('ADMIN_REQUIRED', 403);
  if (data.action === 'withdrawal.prepare') {
    if (Deno.env.get('PLOP_WITHDRAWALS_ENABLED') !== 'true') throw new ApiError('WITHDRAWALS_DISABLED', 403);
    const reference = crypto.randomUUID();
    withdrawalPayload(data.amount, data.method, data.recipient, reference, Math.floor(Date.now() / 1000));
    return (await database('merchant_withdrawals', 'POST', { reference, admin_id: user.id, amount: data.amount, method: data.method, recipient: data.recipient }))[0];
  }
  if (data.action === 'withdrawal.execute' || data.action === 'withdrawal.verify') {
    const rows = await database(`merchant_withdrawals?reference=eq.${uuid(data.reference)}&select=*`);
    if (!rows.length) throw new ApiError('WITHDRAWAL_NOT_FOUND', 404);
    const row = rows[0];
    if (data.action === 'withdrawal.verify') {
      const result = await provider('api/withdraw/marchand/verify', { reference: row.reference }, await merchantToken());
      if (result.data?.reference !== row.reference || !['pending', 'failed', 'success', 'remboursé'].includes(result.data?.status)) throw new ApiError('INVALID_PROVIDER_RESPONSE', 502);
      return (await database(`merchant_withdrawals?reference=eq.${row.reference}`, 'PATCH', { status: result.data.status, transaction_id: String(result.data.transaction_id), updated_at: new Date().toISOString() }))[0];
    }
    if (Deno.env.get('PLOP_WITHDRAWALS_ENABLED') !== 'true') throw new ApiError('WITHDRAWALS_DISABLED', 403);
    if (row.admin_id !== user.id || data.confirmation !== row.reference) throw new ApiError('CONFIRMATION_REQUIRED', 403);
    const token = await merchantToken();
    if (!await database('rpc/claim_withdrawal', 'POST', { p_reference: row.reference })) throw new ApiError('WITHDRAWAL_ALREADY_STARTED', 409);
    const values = { amount: Number(row.amount), method: row.method, recipient: row.recipient, reference: row.reference };
    try {
      const timestamp = Math.floor(Date.now() / 1000);
      const withdrawal_signature = await hmac(withdrawalPayload(values.amount, values.method, values.recipient, values.reference, timestamp), secret('PLOP_CLIENT_SECRET'));
      const signed = await provider('api/auth/marchand/withdrawal-token', { ...values, timestamp, withdrawal_signature }, token);
      if (typeof signed.withdrawal_token !== 'string' || !signed.withdrawal_token) throw new ApiError('INVALID_PROVIDER_RESPONSE', 502);
      const result = await provider('api/withdraw/marchand', values, signed.withdrawal_token);
      if (result.data?.status !== 'success' || !/^\d+$/.test(String(result.data?.api_reference ?? ''))) throw new ApiError('PROVIDER_OUTCOME_UNKNOWN', 502);
      return (await database(`merchant_withdrawals?reference=eq.${row.reference}`, 'PATCH', { status: 'success', transaction_id: String(result.data.transaction_id), updated_at: new Date().toISOString() }))[0];
    } catch (error) {
      // Erè definitif -> 'failed'. Rezilta ensèten (timeout, 5xx) -> rete 'processing'
      // pou 'withdrawal.verify' ka rekonsilye pita.
      const code = error instanceof ApiError ? error.code : 'PROVIDER_OUTCOME_UNKNOWN';
      const definitive = ['INSUFFICIENT_BALANCE', 'TOKEN_ALREADY_USED', 'API_TRANSFER_FAILED', 'DUPLICATE_REFERENCE', 'PARAMETER_MISMATCH', 'INVALID_TOKEN_TYPE', 'INVALID_SIGNATURE', 'TIMESTAMP_EXPIRED', 'METHOD_NOT_CONFIGURED', 'NO_CLIENT_SECRET', 'INVALID_WITHDRAWAL', 'INVALID_PROVIDER_RESPONSE'].includes(code);
      await database(`merchant_withdrawals?reference=eq.${row.reference}`, 'PATCH', { error_code: code, status: definitive ? 'failed' : 'processing', updated_at: new Date().toISOString() });
      throw error;
    }
  }
  throw new ApiError('UNKNOWN_ACTION');
}

export async function handler(request: Request): Promise<Response> {
  const origin = request.headers.get('Origin');
  const allowed = (Deno.env.get('APP_ORIGINS') ?? '').split(',').map(s => s.trim());
  const headers: Record<string,string> = { 'Content-Type': 'application/json', Vary: 'Origin', 'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info, x-webhook-signature', 'Access-Control-Allow-Methods': 'POST, OPTIONS' };
  if (origin && allowed.includes(origin)) headers['Access-Control-Allow-Origin'] = origin;
  if (origin && !allowed.includes(origin)) return new Response(JSON.stringify({ error: 'ORIGIN_DENIED' }), { status: 403, headers });
  if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers });
  if (request.method !== 'POST') return new Response(JSON.stringify({ error: 'METHOD_NOT_ALLOWED' }), { status: 405, headers });
  try {
    const raw = await request.text();
    if (encoder.encode(raw).length > 32768) throw new ApiError('PAYLOAD_TOO_LARGE', 413);
    let data: Data;
    try { data = JSON.parse(raw); } catch { throw new ApiError('INVALID_JSON'); }
    if (!data || Array.isArray(data) || typeof data !== 'object') throw new ApiError('INVALID_JSON');
    const result = await processRequest(request, data, raw);
    return new Response(JSON.stringify(result), { status: 200, headers });
  } catch (error) {
    return new Response(JSON.stringify({ error: error instanceof ApiError ? error.code : 'SERVICE_UNAVAILABLE' }), { status: error instanceof ApiError ? error.status : 503, headers });
  }
}

if (import.meta.main) Deno.serve(handler);
