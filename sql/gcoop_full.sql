-- ============================================================
-- GCOOP - FULL DATABASE SETUP
-- Run this single file to set up the entire database
-- ============================================================

-- ============================================================
-- SECTION 1: EXTENSIONS
-- ============================================================
create extension if not exists "uuid-ossp";

-- ============================================================
-- SECTION 2: TABLES
-- ============================================================

-- Cooperatives
create table cooperatives (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  address text,
  phone text,
  email text,
  ice text,
  rc text,
  logo_url text,
  created_at timestamp with time zone default now()
);

-- Users (extends Supabase auth.users)
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  role text check (role in ('admin', 'admin_cooperative')),
  cooperative_id uuid references cooperatives(id) on delete set null,
  created_at timestamp with time zone default now()
);

-- Clients
create table clients (
  id uuid primary key default uuid_generate_v4(),
  cooperative_id uuid references cooperatives(id) on delete cascade,
  name text not null,
  phone text not null,
  address text not null,
  email text,
  created_at timestamp with time zone default now()
);

-- Suppliers
create table suppliers (
  id uuid primary key default uuid_generate_v4(),
  cooperative_id uuid references cooperatives(id) on delete cascade,
  name text not null,
  phone text not null,
  address text not null,
  email text,
  created_at timestamp with time zone default now()
);

-- Products
create table products (
  id uuid primary key default uuid_generate_v4(),
  cooperative_id uuid references cooperatives(id) on delete cascade,
  supplier_id uuid references suppliers(id) on delete set null,
  name text not null,
  price decimal(10,2) not null,
  stock integer not null default 0,
  min_stock integer default 0,
  photo_url text,
  created_at timestamp with time zone default now()
);

-- Documents (Facture, Devis, BDC, BDL)
create table documents (
  id uuid primary key default uuid_generate_v4(),
  cooperative_id uuid references cooperatives(id) on delete cascade,
  type text check (type in ('FAC','DEV','BDC','BDL')),
  number text not null,
  client_id uuid references clients(id) on delete set null,
  supplier_id uuid references suppliers(id) on delete set null,
  status text default 'draft',
  total decimal(10,2) default 0,
  discount decimal(5,2) default 0,
  date date default current_date,
  notes text,
  linked_document_id uuid references documents(id) on delete set null,
  created_at timestamp with time zone default now()
);

-- Document Items
create table document_items (
  id uuid primary key default uuid_generate_v4(),
  document_id uuid references documents(id) on delete cascade,
  product_id uuid references products(id) on delete set null,
  quantity integer not null,
  unit_price decimal(10,2) not null,
  total decimal(10,2) generated always as (quantity * unit_price) stored
);

-- Expenses
create table expenses (
  id uuid primary key default uuid_generate_v4(),
  cooperative_id uuid references cooperatives(id) on delete cascade,
  category text not null,
  amount decimal(10,2) not null,
  date date default current_date,
  note text,
  created_at timestamp with time zone default now()
);

-- Invitations
create table invitations (
  id uuid primary key default uuid_generate_v4(),
  email text not null,
  cooperative_name text not null,
  token text unique not null default uuid_generate_v4()::text,
  status text default 'pending' check (status in ('pending','accepted','expired')),
  created_at timestamp with time zone default now(),
  expires_at timestamp with time zone default (now() + interval '7 days')
);

-- ============================================================
-- SECTION 3: ROW LEVEL SECURITY (RLS)
-- ============================================================

alter table cooperatives enable row level security;
alter table profiles enable row level security;
alter table clients enable row level security;
alter table suppliers enable row level security;
alter table products enable row level security;
alter table documents enable row level security;
alter table document_items enable row level security;
alter table expenses enable row level security;
alter table invitations enable row level security;

create policy "Users see own profile" on profiles
  for select using (auth.uid() = id);

create policy "Admins see all profiles" on profiles
  for select using ((select role from profiles where id = auth.uid()) = 'admin');

create policy "cooperative access" on cooperatives
  for all using (
    id = (select cooperative_id from profiles where id = auth.uid())
    or (select role from profiles where id = auth.uid()) = 'admin'
  );

create policy "clients_cooperative_access" on clients
  for all using (cooperative_id = (select cooperative_id from profiles where id = auth.uid()));

create policy "suppliers_cooperative_access" on suppliers
  for all using (cooperative_id = (select cooperative_id from profiles where id = auth.uid()));

create policy "products_cooperative_access" on products
  for all using (cooperative_id = (select cooperative_id from profiles where id = auth.uid()));

create policy "documents_cooperative_access" on documents
  for all using (cooperative_id = (select cooperative_id from profiles where id = auth.uid()));

create policy "document_items_cooperative_access" on document_items
  for all using (
    document_id in (select id from documents where cooperative_id = (select cooperative_id from profiles where id = auth.uid()))
  );

create policy "expenses_cooperative_access" on expenses
  for all using (cooperative_id = (select cooperative_id from profiles where id = auth.uid()));

create policy "invitations_admin_access" on invitations
  for all using ((select role from profiles where id = auth.uid()) = 'admin');

-- ============================================================
-- SECTION 4: FUNCTIONS & TRIGGERS
-- ============================================================

-- Auto update stock when document is validated
create or replace function update_stock_on_document()
returns trigger as $$
begin
  if NEW.status = 'validated' and (OLD.status is null or OLD.status != 'validated') then
    if NEW.type = 'FAC' then
      update products p
      set stock = stock - di.quantity
      from document_items di
      where di.document_id = NEW.id and di.product_id = p.id;
    elsif NEW.type = 'BDC' then
      update products p
      set stock = stock + di.quantity
      from document_items di
      where di.document_id = NEW.id and di.product_id = p.id;
    end if;
  end if;
  return NEW;
end;
$$ language plpgsql;

create trigger trigger_update_stock
after update on documents
for each row execute function update_stock_on_document();

-- Auto generate document number
create or replace function generate_document_number(
  p_cooperative_id uuid,
  p_type text
)
returns text as $$
declare
  v_count integer;
begin
  select count(*) into v_count
  from documents
  where cooperative_id = p_cooperative_id and type = p_type;
  return p_type || '-' || lpad((v_count + 1)::text, 3, '0');
end;
$$ language plpgsql;

-- ============================================================
-- SECTION 5: STORAGE BUCKETS
-- ============================================================

insert into storage.buckets (id, name, public)
values ('product-photos', 'product-photos', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('company-logos', 'company-logos', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('documents-pdf', 'documents-pdf', false)
on conflict (id) do nothing;

create policy "Public product photos" on storage.objects
  for select using (bucket_id = 'product-photos');

create policy "Authenticated upload product photos" on storage.objects
  for insert with check (
    bucket_id = 'product-photos' and auth.role() = 'authenticated'
  );

create policy "Public logos" on storage.objects
  for select using (bucket_id = 'company-logos');

create policy "Authenticated upload logos" on storage.objects
  for insert with check (
    bucket_id = 'company-logos' and auth.role() = 'authenticated'
  );

-- ============================================================
-- SECTION 6: SEED DATA (optional)
-- ============================================================

-- Insert test admin user (run after creating user via Supabase Auth dashboard)
-- insert into profiles (id, email, full_name, role)
-- values ('YOUR_AUTH_UUID', 'admin@gcoop.ma', 'Super Admin', 'admin');
