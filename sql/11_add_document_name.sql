-- ============================================================
-- MIGRATION: Add document name field
-- ============================================================

ALTER TABLE documents ADD COLUMN IF NOT EXISTS name TEXT;
