-- ============================================================
-- 09_suppliers_clients_expenses_setup.sql
-- ============================================================

-- 1. Create Tables if missing
CREATE TABLE IF NOT EXISTS public.suppliers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cooperative_id UUID REFERENCES public.cooperatives(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    address TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cooperative_id UUID REFERENCES public.cooperatives(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    address TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cooperative_id UUID REFERENCES public.cooperatives(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    date DATE DEFAULT CURRENT_DATE,
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Enable RLS
ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

-- 3. RLS Policies
-- SUPPLIERS
DROP POLICY IF EXISTS "suppliers_cooperative_access" ON public.suppliers;
CREATE POLICY "suppliers_cooperative_access" ON public.suppliers
FOR ALL USING (cooperative_id = (SELECT cooperative_id FROM public.profiles WHERE id = auth.uid()));

-- CLIENTS
DROP POLICY IF EXISTS "clients_cooperative_access" ON public.clients;
CREATE POLICY "clients_cooperative_access" ON public.clients
FOR ALL USING (cooperative_id = (SELECT cooperative_id FROM public.profiles WHERE id = auth.uid()));

-- EXPENSES
DROP POLICY IF EXISTS "expenses_cooperative_access" ON public.expenses;
CREATE POLICY "expenses_cooperative_access" ON public.expenses
FOR ALL USING (cooperative_id = (SELECT cooperative_id FROM public.profiles WHERE id = auth.uid()));
