-- 07_invitation_trigger.sql

-- 1. Update cooperatives table with new required fields
ALTER TABLE cooperatives ADD COLUMN IF NOT EXISTS name_ar TEXT;
ALTER TABLE cooperatives ADD COLUMN IF NOT EXISTS name_fr TEXT;

-- 2. Create the trigger function for new invitations
-- Note: This trigger is intended to be used with Supabase Database Webhooks.
-- In the Supabase Dashboard, you should create a Webhook for the 'invitations' table
-- on 'INSERT' events that calls the 'send-invitation' Edge Function.

-- If you prefer to use SQL for the webhook (requires pg_net extension):
/*
CREATE OR REPLACE FUNCTION public.handle_new_invitation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  PERFORM
    net.http_post(
      url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-invitation',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY'
      ),
      body := jsonb_build_object('record', row_to_json(NEW))
    );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_invitation_created
  AFTER INSERT ON public.invitations
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_invitation();
*/

-- 3. Ensure the 'company-logos' bucket is public (if not already set in gcoop_full.sql)
-- This is already in gcoop_full.sql but we ensure it here too.
INSERT INTO storage.buckets (id, name, public)
VALUES ('company-logos', 'company-logos', true)
ON CONFLICT (id) DO NOTHING;

-- 4. Add RLS policy for company-logos if missing
CREATE POLICY "Public Access Logos" ON storage.objects
  FOR SELECT USING (bucket_id = 'company-logos');

CREATE POLICY "Authenticated Upload Logos" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'company-logos' AND auth.role() = 'authenticated');
