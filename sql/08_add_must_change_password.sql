-- Add must_change_password to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS must_change_password BOOLEAN DEFAULT TRUE;

-- Ensure cooperatives has name_ar and name_fr
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='cooperatives' AND column_name='name_ar') THEN
        ALTER TABLE cooperatives ADD COLUMN name_ar TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='cooperatives' AND column_name='name_fr') THEN
        ALTER TABLE cooperatives ADD COLUMN name_fr TEXT;
    END IF;
END $$;
