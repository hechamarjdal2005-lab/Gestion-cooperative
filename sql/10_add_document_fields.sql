-- ============================================================
-- MIGRATION: Add new document fields for enhanced document management
-- ============================================================

-- Add new columns to documents table
ALTER TABLE documents ADD COLUMN IF NOT EXISTS tva_rate DECIMAL(5,2) DEFAULT 0;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS tva_amount DECIMAL(10,2) DEFAULT 0;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS delivery_fees DECIMAL(10,2) DEFAULT 0;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS payment_method TEXT;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS delivery_location TEXT;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS delivery_delay TEXT;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS linked_order_ref TEXT;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS signature_client TEXT;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS additional_info TEXT;

-- Add new columns to document_items table
ALTER TABLE document_items ADD COLUMN IF NOT EXISTS product_ref TEXT;
ALTER TABLE document_items ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE document_items ADD COLUMN IF NOT EXISTS unit TEXT DEFAULT 'Pièce';

-- Update document type check to include BDL
ALTER TABLE documents DROP CONSTRAINT IF EXISTS documents_type_check;
ALTER TABLE documents ADD CONSTRAINT documents_type_check 
  CHECK (type IN ('FAC', 'DEV', 'BDC', 'BDL'));
