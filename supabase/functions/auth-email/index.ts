// Supabase Auth "Send Email Hook": voye imèl Auth yo (modpas bliye, magic link, envitasyon...)
// atravè API Brevo olye SMTP Supabase la (ki voye sèlman bay manm ekip la).
// Sekrè: SEND_EMAIL_HOOK_SECRET (v1,whsec_...), BREVO_API_KEY, FROM_EMAIL, FROM_NAME.
// Deplwaye: supabase functions deploy auth-email --no-verify-jwt
import { Webhook } from 'https://esm.sh/standardwebhooks@1.0.0';

type EmailData = {
  token: string; token_hash: string; redirect_to: string; email_action_type: string;
  site_url: string; token_new?: string; token_hash_new?: string;
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });

const escape = (s: string) => s.replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]!);

const texts: Record<string, { subject: string; intro: string; button: string }> = {
  recovery: { subject: 'Reset modpas ou / Réinitialiser votre mot de passe', intro: 'Nou resevwa yon demann pou chanje modpas ou. Klike sou bouton an pou w chwazi yon nouvo modpas.<br>Nous avons reçu une demande de réinitialisation de votre mot de passe.', button: 'Chanje modpas / Réinitialiser' },
  magiclink: { subject: 'Lyen koneksyon / Lien de connexion', intro: 'Klike sou bouton an pou w konekte.<br>Cliquez sur le bouton pour vous connecter.', button: 'Konekte / Se connecter' },
  signup: { subject: 'Konfime imèl ou / Confirmez votre email', intro: 'Klike sou bouton an pou w konfime kont ou.<br>Cliquez sur le bouton pour confirmer votre compte.', button: 'Konfime / Confirmer' },
  invite: { subject: 'Envitasyon / Invitation', intro: 'Yo envite w kreye yon kont.<br>Vous avez été invité à créer un compte.', button: 'Aksepte / Accepter' },
  email_change: { subject: 'Konfime nouvo imèl / Confirmez le changement d\'email', intro: 'Klike sou bouton an pou w konfime chanjman imèl la.<br>Cliquez pour confirmer le changement d\'email.', button: 'Konfime / Confirmer' },
};

async function send(to: string, subject: string, html: string, senderName: string) {
  const res = await fetch('https://api.brevo.com/v3/smtp/email', {
    method: 'POST',
    headers: { 'api-key': Deno.env.get('BREVO_API_KEY') ?? '', 'Content-Type': 'application/json', accept: 'application/json' },
    body: JSON.stringify({ sender: { email: Deno.env.get('FROM_EMAIL'), name: senderName }, to: [{ email: to }], subject, htmlContent: html }),
  });
  if (!res.ok) throw new Error(`Brevo ${res.status}: ${(await res.text()).slice(0, 300)}`);
}

function render(appName: string, action: string, link: string, code: string) {
  const t = texts[action] ?? { subject: 'Kòd verifikasyon / Code de vérification', intro: 'Men kòd verifikasyon ou.<br>Voici votre code de vérification.', button: '' };
  const html = `<div style="font-family:Arial,sans-serif;max-width:520px;margin:auto;padding:24px">
<h2 style="color:#D90429">${escape(appName)}</h2><p>${t.intro}</p>
${t.button ? `<p style="margin:28px 0"><a href="${escape(link)}" style="background:#D90429;color:#fff;padding:12px 22px;border-radius:8px;text-decoration:none;font-weight:bold">${t.button}</a></p>` : ''}
<p>Kòd / Code: <b style="font-size:18px;letter-spacing:2px">${escape(code)}</b></p>
<p style="color:#777;font-size:12px">Si se pa ou ki fè demann sa a, pa okipe imèl sa a. / Si vous n'êtes pas à l'origine de cette demande, ignorez cet email.</p></div>`;
  return { subject: `${appName} — ${t.subject}`, html };
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return json({ error: 'METHOD_NOT_ALLOWED' }, 405);
  const payload = await req.text();
  let data: { user: { email: string; new_email?: string }; email_data: EmailData };
  try {
    const secret = (Deno.env.get('SEND_EMAIL_HOOK_SECRET') ?? '').replace('v1,whsec_', '');
    data = new Webhook(secret).verify(payload, Object.fromEntries(req.headers)) as typeof data;
  } catch {
    return json({ error: { http_code: 401, message: 'Invalid hook signature' } }, 401);
  }
  const { user, email_data: e } = data;
  const redirect = e.redirect_to || e.site_url;
  const appName = /redlight/i.test(redirect) ? 'REDLIGHT AUTOPARTS' : (Deno.env.get('FROM_NAME') || 'Support');
  const verify = (hash: string) => `${Deno.env.get('SUPABASE_URL')}/auth/v1/verify?token=${encodeURIComponent(hash)}&type=${encodeURIComponent(e.email_action_type)}&redirect_to=${encodeURIComponent(redirect)}`;
  try {
    if (e.email_action_type === 'email_change' && user.new_email) {
      // Auth: token_hash ale nan nouvo imèl la, token_hash_new nan ansyen an.
      const n = render(appName, 'email_change', verify(e.token_hash), e.token);
      await send(user.new_email, n.subject, n.html, appName);
      if (e.token_hash_new) {
        const o = render(appName, 'email_change', verify(e.token_hash_new), e.token_new ?? '');
        await send(user.email, o.subject, o.html, appName);
      }
    } else {
      const m = render(appName, e.email_action_type, verify(e.token_hash), e.token);
      await send(user.email, m.subject, m.html, appName);
    }
  } catch (error) {
    console.error(error);
    return json({ error: { http_code: 500, message: 'Email delivery failed' } }, 500);
  }
  return json({});
});
