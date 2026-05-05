-- ============================================================
-- 08_clients_expenses_policies.sql
-- ============================================================

-- 1. Tables Creation (if not already existing)
-- Clients
CREATE TABLE IF NOT EXISTS public.clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cooperative_id UUID REFERENCES public.cooperatives(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT,
    address TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Expenses
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
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

-- 3. RLS Policies for CLIENTS
-- Allow select for members of the same cooperative
CREATE POLICY "Users can view their cooperative's clients" ON public.clients
FOR SELECT USING (
    cooperative_id = (SELECT cooperative_id FROM public.profiles WHERE id = auth.uid())
);

-- Allow insert for members of the same cooperative
CREATE POLICY "Users can insert clients for their cooperative" ON public.clients
FOR INSERT WITH CHECK (
    cooperative_id = (SELECT cooperative_id FROM public.profiles WHERE id = auth.uid())
);

-- Allow update for members of the same cooperative
CREATE POLICY "Users can update their cooperative's clients" ON public.clients
FOR UPDATE USING (
    cooperative_id = (SELECT cooperative_id FROM public.profiles WHERE id = auth.uid())
);

-- 4. RLS Policies for EXPENSES
-- Allow select for members of the same cooperative
CREATE POLICY "Users can view their cooperative's expenses" ON public.expenses
FOR SELECT USING (
    cooperative_id = (SELECT cooperative_id FROM public.profiles WHERE id = auth.uid())
);

-- Allow insert for members of the same cooperative
CREATE POLICY "Users can insert expenses for their cooperative" ON public.expenses
FOR INSERT WITH CHECK (
    cooperative_id = (SELECT cooperative_id FROM public.profiles WHERE id = auth.uid())
);

-- Allow update/delete for members of the same cooperative
CREATE POLICY "Users can modify their cooperative's expenses" ON public.expenses
FOR ALL USING (
    cooperative_id = (SELECT cooperative_id FROM public.profiles WHERE id = auth.uid())
);
