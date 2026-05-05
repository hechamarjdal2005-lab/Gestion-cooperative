import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')

serve(async (req) => {
  try {
    const { record } = await req.json()
    const { email, cooperative_name, token } = record

    if (!RESEND_API_KEY) {
      return new Response(
        JSON.stringify({ error: 'RESEND_API_KEY is not set' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: 'GCoop <onboarding@resend.dev>',
        to: [email],
        subject: `Invitation à rejoindre ${cooperative_name}`,
        html: `
          <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e5e7eb; border-radius: 8px;">
            <h2 style="color: #1E3A8A;">Bienvenue sur GCoop !</h2>
            <p>Bonjour,</p>
            <p>Vous avez été invité à gérer la coopérative <strong>${cooperative_name}</strong> sur GCoop.</p>
            <p>GCoop est votre solution de gestion commerciale simplifiée, conçue pour vous aider à gérer vos stocks, vos clients et vos documents commerciaux.</p>
            <div style="margin: 30px 0; text-align: center;">
              <a href="https://gcoop.app/accept-invitation?token=${token}" 
                 style="background-color: #1E3A8A; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; font-weight: bold; display: inline-block;">
                Accepter l'invitation
              </a>
            </div>
            <p>Si le bouton ne fonctionne pas, copiez et collez ce lien dans votre navigateur :</p>
            <p style="word-break: break-all; color: #6b7280;">https://gcoop.app/accept-invitation?token=${token}</p>
            <hr style="border: 0; border-top: 1px solid #e5e7eb; margin: 20px 0;">
            <p style="font-size: 12px; color: #9ca3af;">Cet email a été envoyé automatiquement par GCoop. Si vous n'attendiez pas cette invitation, vous pouvez ignorer cet email.</p>
          </div>
        `,
      }),
    })

    const data = await res.json()
    return new Response(JSON.stringify(data), {
      status: res.status,
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
