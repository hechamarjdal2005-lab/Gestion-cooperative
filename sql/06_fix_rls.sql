-- ============================================================
-- FIX RLS RECURSION BUG
-- This script drops all recursive policies and recreates them
-- using security definer functions to avoid infinite loops.
-- ============================================================

-- 1. Drop ALL existing policies on ALL tables
DO $$ 
DECLARE 
    pol RECORD;
BEGIN 
    FOR pol IN (SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'public') 
    LOOP 
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', pol.policyname, pol.tablename);
    END LOOP;
END $$;

-- 2. Create security definer functions to safely fetch user data
-- These functions run with the privileges of the creator (postgres),
-- thus avoiding the RLS check on the profiles table itself.

CREATE OR REPLACE FUNCTION public.get_auth_role()
RETURNS text AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.get_auth_cooperative_id()
RETURNS uuid AS $$
  SELECT cooperative_id FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;

-- 3. Recreate all policies correctly

-- PROFILES
-- Users can always see and edit their own profile
CREATE POLICY "profiles_self_access" ON public.profiles
  FOR ALL USING (auth.uid() = id);

-- Super admins can see all profiles
CREATE POLICY "profiles_admin_select" ON public.profiles
  FOR SELECT USING (public.get_auth_role() = 'admin');

-- COOPERATIVES
-- Cooperative admins can see their own cooperative
-- Super admins can see all cooperatives
CREATE POLICY "cooperatives_access" ON public.cooperatives
  FOR ALL USING (
    id = public.get_auth_cooperative_id()
    OR public.get_auth_role() = 'admin'
  );

-- CLIENTS
CREATE POLICY "clients_access" ON public.clients
  FOR ALL USING (cooperative_id = public.get_auth_cooperative_id());

-- SUPPLIERS
CREATE POLICY "suppliers_access" ON public.suppliers
  FOR ALL USING (cooperative_id = public.get_auth_cooperative_id());

-- PRODUCTS
CREATE POLICY "products_access" ON public.products
  FOR ALL USING (cooperative_id = public.get_auth_cooperative_id());

-- DOCUMENTS
CREATE POLICY "documents_access" ON public.documents
  FOR ALL USING (cooperative_id = public.get_auth_cooperative_id());

-- DOCUMENT_ITEMS
-- Users can access items belonging to documents of their cooperative
CREATE POLICY "document_items_access" ON public.document_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.documents d 
      WHERE d.id = document_id 
      AND d.cooperative_id = public.get_auth_cooperative_id()
    )
  );

-- EXPENSES
CREATE POLICY "expenses_access" ON public.expenses
  FOR ALL USING (cooperative_id = public.get_auth_cooperative_id());

-- INVITATIONS
-- Only super admins can manage invitations
CREATE POLICY "invitations_admin_access" ON public.invitations
  FOR ALL USING (public.get_auth_role() = 'admin');
