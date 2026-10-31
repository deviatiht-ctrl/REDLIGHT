import { hmac, validSignature, withdrawalPayload, paymentUrl, handler, parseAmount, normalizeVerification, sameSecret } from './index.ts';

function assert(value: unknown): asserts value {
  if (!value) throw new Error('Assertion failed');
}

Deno.test('HMAC SHA256 uses exact raw bytes', async () => {
  const digest = await hmac('The quick brown fox jumps over the lazy dog', 'key');
  assert(digest === 'f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8');
  assert(await validSignature('The quick brown fox jumps over the lazy dog', `sha256=${digest}`, 'key'));
  assert(!await validSignature('The quick brown fox jumps over the lazy dog ', `sha256=${digest}`, 'key'));
  assert(!await validSignature('payload', '', 'key'));
  assert(!await validSignature('payload', 'sha256=zz', 'key'));
});

Deno.test('Withdrawal signature binds exact amount, recipient, method, reference and timestamp', () => {
  assert(withdrawalPayload(500, 'natcash', '50912345678', 'CMD-001', 1715691234) === '500|natcash|50912345678|CMD-001|1715691234');
  for (const values of [[-1,'natcash','50912345678'], [1.001,'moncash','50912345678'], [500,'carte','50912345678'], [500,'natcash','123']]) {
    let rejected = false;
    try { withdrawalPayload(values[0] as number, values[1] as string, values[2] as string, 'CMD-001', 1715691234); } catch { rejected = true; }
    assert(rejected);
  }
});

Deno.test('Payment URLs reject executable and insecure schemes', () => {
  assert(paymentUrl(null) === null);
  for (const value of ['javascript:alert(1)', 'http://example.com', 'https://user:password@example.com']) {
    let rejected = false;
    try { paymentUrl(value); } catch { rejected = true; }
    assert(rejected);
  }
});

Deno.test('Payment amounts are parsed to cents from provider formats', () => {
  assert(parseAmount(1500) === 1500);
  assert(parseAmount('1500.00') === 1500);
  assert(parseAmount('1,500.50') === 1500.5);
  assert(parseAmount('1500,5') === 1500.5);
  assert(parseAmount('1 500 HTG') === 1500);
  assert(parseAmount(null) === null);
  assert(parseAmount('abc') === null);
});

Deno.test('Verification is normalized without rejecting a different transaction id', () => {
  const paid = normalizeVerification({ trans_status: 'OK', id_transaction: 12345, montant: '500.00', method: 'MonCash' });
  assert(paid.paid && paid.status === 'ok' && paid.transaction === '12345' && paid.amount === 500 && paid.method === 'moncash');
  const pending = normalizeVerification({ trans_status: 'no', montant: '500' });
  assert(!pending.paid && pending.transaction === null);
  assert(!normalizeVerification({ trans_status: 'failed' }).paid);
  assert(!normalizeVerification({}).paid);
});

Deno.test('Reconcile secret comparison', () => {
  assert(sameSecret('abc123', 'abc123'));
  assert(!sameSecret('abc12', 'abc123'));
  assert(!sameSecret('', 'abc123'));
});

Deno.test('Public entry point rejects unsupported methods and malformed bodies before side effects', async () => {
  assert((await handler(new Request('https://example.com', { method: 'GET' }))).status === 405);
  for (const body of ['{', 'null', '[]', '"text"']) {
    const response = await handler(new Request('https://example.com', { method: 'POST', body }));
    assert(response.status === 400);
  }
  const response = await handler(new Request('https://example.com', { method: 'POST', body: '{"action":"payment.start"}' }));
  assert(response.status === 401);
});
