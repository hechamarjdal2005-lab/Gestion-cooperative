create table incomes (
  id uuid primary key default uuid_generate_v4(),
  cooperative_id uuid references cooperatives(id) on delete cascade,
  category text not null,
  amount decimal(10,2) not null,
  date date default current_date,
  note text,
  source text default 'manual' check (source in ('manual', 'invoice')),
  document_id uuid references documents(id),
  created_at timestamp default now()
);

alter table incomes enable row level security;

create policy "cooperative_income_access" on incomes
  for all using (
    cooperative_id = (
      select cooperative_id from profiles 
      where id = auth.uid()
    )
  );

create or replace function add_income_on_invoice()
returns trigger as $$
begin
  if NEW.status = 'validated' and OLD.status != 'validated' and NEW.type = 'FAC' then
    insert into incomes (cooperative_id, category, amount, date, source, document_id)
    values (NEW.cooperative_id, 'مبيعات', NEW.total, NEW.date, 'invoice', NEW.id);
  end if;
  return NEW;
end;
$$ language plpgsql;

create trigger trigger_add_income_on_invoice
after update on documents
for each row execute function add_income_on_invoice();
