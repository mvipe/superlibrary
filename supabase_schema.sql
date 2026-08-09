-- =====================================================================
-- SuperLibrary - Supabase schema (v2, live/CRUD)
-- Run this in: Supabase Dashboard -> SQL Editor -> New query -> Run
--
-- IMPORTANT one-time setting:
--   Auth -> Providers -> Email -> turn OFF "Confirm email".
--   (The app bridges the MSG91-verified phone to an email/password session;
--    with email confirmation ON, first login cannot create a session.)
-- =====================================================================

-- ---------------------------------------------------------------------
-- SAFE TO RE-RUN: this whole script is additive. It only CREATEs tables /
-- columns that don't exist yet and never drops anything, so your existing
-- data is preserved every time you run it.
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- Libraries (one per admin account; owner_id = the signed-in user)
-- ---------------------------------------------------------------------
create table if not exists libraries (
  id           uuid primary key default gen_random_uuid(),
  owner_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name         text not null,
  admin_name   text,
  admin_phone  text,
  admin_email  text,
  total_seats  int not null default 30,
  plan         text not null default 'free',
  plan_expires_at timestamptz,
  referral_code   text,
  created_at   timestamptz default now()
);
create index if not exists idx_lib_owner on libraries(owner_id);

-- ---------------------------------------------------------------------
-- Members
-- ---------------------------------------------------------------------
create table if not exists members (
  id           uuid primary key default gen_random_uuid(),
  library_id   uuid references libraries(id) on delete cascade,
  member_code  text,
  name         text not null,
  email        text,
  phone        text,
  status       text not null default 'active'
               check (status in ('active','inactive','expired')),
  photo_url    text,
  seat_no      text,
  plan         text,
  joined_at    timestamptz default now(),
  expires_at   timestamptz,
  created_at   timestamptz default now()
);
create index if not exists idx_members_library on members(library_id);

-- ---------------------------------------------------------------------
-- Books
-- ---------------------------------------------------------------------
create table if not exists books (
  id               uuid primary key default gen_random_uuid(),
  library_id       uuid references libraries(id) on delete cascade,
  title            text not null,
  author           text,
  isbn             text,
  category         text default 'General',
  total_copies     int  not null default 1,
  available_copies int  not null default 1,
  cover_url        text,
  accent           bigint,   -- ARGB colour value
  created_at       timestamptz default now()
);
create index if not exists idx_books_library on books(library_id);

-- ---------------------------------------------------------------------
-- Transactions (issue / return)
-- ---------------------------------------------------------------------
create table if not exists transactions (
  id           uuid primary key default gen_random_uuid(),
  library_id   uuid references libraries(id) on delete cascade,
  book_id      uuid references books(id) on delete set null,
  member_id    uuid references members(id) on delete set null,
  book_title   text,
  member_name  text,
  type         text not null default 'issue' check (type in ('issue','return')),
  due_at       timestamptz,
  fine_amount  numeric(10,2) default 0,
  created_at   timestamptz default now()
);
create index if not exists idx_txn_library on transactions(library_id);

-- ---------------------------------------------------------------------
-- Payments (membership + fines)
-- ---------------------------------------------------------------------
create table if not exists payments (
  id           uuid primary key default gen_random_uuid(),
  library_id   uuid references libraries(id) on delete cascade,
  member_id    uuid references members(id) on delete set null,
  member_name  text,
  member_code  text,
  type         text not null check (type in ('membership','fine')),
  amount       numeric(10,2) not null,
  status       text not null default 'paid'
               check (status in ('paid','pending','overdue')),
  method       text default 'cash',
  paid_at      timestamptz,
  created_at   timestamptz default now()
);
create index if not exists idx_pay_library on payments(library_id);

-- ---------------------------------------------------------------------
-- Attendance
-- ---------------------------------------------------------------------
create table if not exists attendance (
  id           uuid primary key default gen_random_uuid(),
  library_id   uuid references libraries(id) on delete cascade,
  member_id    uuid references members(id) on delete set null,
  member_name  text,
  marked_at    timestamptz default now(),
  state        text not null default 'present'
               check (state in ('present','absent','pending'))
);
create index if not exists idx_att_library on attendance(library_id);

-- ---------------------------------------------------------------------
-- Shifts (timing slots with their own fee)
-- ---------------------------------------------------------------------
create table if not exists shifts (
  id           uuid primary key default gen_random_uuid(),
  library_id   uuid references libraries(id) on delete cascade,
  name         text not null,
  start_time   text,
  end_time     text,
  fee          numeric(10,2) default 0,
  created_at   timestamptz default now()
);
create index if not exists idx_shift_library on shifts(library_id);

-- ---------------------------------------------------------------------
-- Seat allotments (one member holds one seat in one shift)
-- ---------------------------------------------------------------------
create table if not exists seat_allotments (
  id           uuid primary key default gen_random_uuid(),
  library_id   uuid references libraries(id) on delete cascade,
  seat_no      int not null,
  shift        text not null,
  member_id    uuid references members(id) on delete cascade,
  member_name  text,
  created_at   timestamptz default now(),
  unique (library_id, seat_no, shift)
);
create index if not exists idx_seat_library on seat_allotments(library_id);

-- ---------------------------------------------------------------------
-- Enquiries (walk-in leads)
-- ---------------------------------------------------------------------
create table if not exists enquiries (
  id           uuid primary key default gen_random_uuid(),
  library_id   uuid references libraries(id) on delete cascade,
  name         text not null,
  phone        text,
  note         text,
  status       text not null default 'fresh'
               check (status in ('fresh','followUp','converted','closed')),
  created_at   timestamptz default now()
);
create index if not exists idx_enq_library on enquiries(library_id);

-- ---------------------------------------------------------------------
-- Expenses
-- ---------------------------------------------------------------------
create table if not exists expenses (
  id           uuid primary key default gen_random_uuid(),
  library_id   uuid references libraries(id) on delete cascade,
  title        text not null,
  amount       numeric(10,2) not null default 0,
  note         text,
  spent_on     timestamptz default now(),
  created_at   timestamptz default now()
);
create index if not exists idx_exp_library on expenses(library_id);

-- ---------------------------------------------------------------------
-- Taxes
-- ---------------------------------------------------------------------
create table if not exists taxes (
  id           uuid primary key default gen_random_uuid(),
  library_id   uuid references libraries(id) on delete cascade,
  name         text not null,
  percent      numeric(6,2) not null default 0,
  created_at   timestamptz default now()
);
create index if not exists idx_tax_library on taxes(library_id);

-- ---------------------------------------------------------------------
-- Referrals (a referred library links to the referrer via their code)
-- ---------------------------------------------------------------------
create table if not exists referrals (
  id                  uuid primary key default gen_random_uuid(),
  referrer_code       text not null,
  referred_library_id uuid references libraries(id) on delete cascade,
  referred_name       text,
  reward              numeric(10,2) default 200,
  status              text not null default 'pending'
                      check (status in ('pending','credited')),
  created_at          timestamptz default now()
);
create index if not exists idx_ref_code on referrals(referrer_code);

-- ---------------------------------------------------------------------
-- Invoices
-- ---------------------------------------------------------------------
create table if not exists invoices (
  id           uuid primary key default gen_random_uuid(),
  library_id   uuid references libraries(id) on delete cascade,
  invoice_no   text,
  bill_to      text,
  phone        text,
  date         timestamptz default now(),
  items        jsonb default '[]'::jsonb,
  tax_percent  numeric(6,2) default 0,
  notes        text,
  created_at   timestamptz default now()
);
create index if not exists idx_inv_library on invoices(library_id);

-- =====================================================================
-- Additive column migrations (safe on tables created by older versions).
-- Each only runs if the column is missing — no data is touched.
-- =====================================================================
alter table libraries add column if not exists owner_id uuid references auth.users(id) on delete cascade;
alter table libraries add column if not exists admin_name text;
alter table libraries add column if not exists total_seats int not null default 30;
alter table libraries add column if not exists plan text not null default 'free';
alter table libraries add column if not exists plan_expires_at timestamptz;
alter table libraries add column if not exists referral_code text;

alter table members add column if not exists seat_no text;
alter table members add column if not exists plan text;
alter table members add column if not exists photo_url text;
alter table members add column if not exists joined_at timestamptz default now();
alter table members add column if not exists expires_at timestamptz;
alter table members add column if not exists address text;
alter table members add column if not exists gender text;
alter table members add column if not exists is_vip boolean default false;
alter table members add column if not exists start_date timestamptz;
alter table members add column if not exists bill_date timestamptz;
alter table members add column if not exists payment_method text;
alter table members add column if not exists due_amount numeric(10,2) default 0;
alter table members add column if not exists due_reminder timestamptz;
alter table members add column if not exists dob timestamptz;
alter table members add column if not exists home_phone text;
alter table members add column if not exists father_name text;
alter table members add column if not exists unique_id text;
alter table members add column if not exists institute text;
alter table members add column if not exists course text;
alter table members add column if not exists marriage_anniversary timestamptz;
alter table members add column if not exists batch_start text;
alter table members add column if not exists batch_end text;
alter table members add column if not exists remark text;
alter table members add column if not exists documents jsonb default '[]'::jsonb;

alter table books add column if not exists category text default 'General';
alter table books add column if not exists accent bigint;
alter table books add column if not exists cover_url text;

alter table payments add column if not exists method text default 'cash';
alter table payments add column if not exists member_name text;
alter table payments add column if not exists member_code text;
alter table payments add column if not exists paid_at timestamptz;

alter table transactions add column if not exists book_title text;
alter table transactions add column if not exists member_name text;
alter table transactions add column if not exists type text default 'issue';
alter table transactions add column if not exists due_at timestamptz;
alter table transactions add column if not exists fine_amount numeric(10,2) default 0;

alter table attendance add column if not exists member_name text;
alter table attendance add column if not exists marked_at timestamptz default now();
alter table attendance add column if not exists state text default 'present';

-- =====================================================================
-- Row Level Security
-- =====================================================================
alter table libraries    enable row level security;
alter table members      enable row level security;
alter table books        enable row level security;
alter table transactions enable row level security;
alter table payments     enable row level security;
alter table attendance   enable row level security;
alter table shifts          enable row level security;
alter table seat_allotments enable row level security;
alter table enquiries       enable row level security;
alter table expenses        enable row level security;
alter table taxes           enable row level security;
alter table referrals       enable row level security;
alter table invoices        enable row level security;

-- Libraries: an admin can only see / manage their own library.
drop policy if exists "own libraries" on libraries;
create policy "own libraries" on libraries
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

-- Child tables: rows must belong to a library the user owns.
-- (helper condition reused for every child table)
drop policy if exists "own members" on members;
create policy "own members" on members for all
  using (library_id in (select id from libraries where owner_id = auth.uid()))
  with check (library_id in (select id from libraries where owner_id = auth.uid()));

drop policy if exists "own books" on books;
create policy "own books" on books for all
  using (library_id in (select id from libraries where owner_id = auth.uid()))
  with check (library_id in (select id from libraries where owner_id = auth.uid()));

drop policy if exists "own txns" on transactions;
create policy "own txns" on transactions for all
  using (library_id in (select id from libraries where owner_id = auth.uid()))
  with check (library_id in (select id from libraries where owner_id = auth.uid()));

drop policy if exists "own payments" on payments;
create policy "own payments" on payments for all
  using (library_id in (select id from libraries where owner_id = auth.uid()))
  with check (library_id in (select id from libraries where owner_id = auth.uid()));

drop policy if exists "own attendance" on attendance;
create policy "own attendance" on attendance for all
  using (library_id in (select id from libraries where owner_id = auth.uid()))
  with check (library_id in (select id from libraries where owner_id = auth.uid()));

drop policy if exists "own shifts" on shifts;
create policy "own shifts" on shifts for all
  using (library_id in (select id from libraries where owner_id = auth.uid()))
  with check (library_id in (select id from libraries where owner_id = auth.uid()));

drop policy if exists "own seats" on seat_allotments;
create policy "own seats" on seat_allotments for all
  using (library_id in (select id from libraries where owner_id = auth.uid()))
  with check (library_id in (select id from libraries where owner_id = auth.uid()));

drop policy if exists "own enquiries" on enquiries;
create policy "own enquiries" on enquiries for all
  using (library_id in (select id from libraries where owner_id = auth.uid()))
  with check (library_id in (select id from libraries where owner_id = auth.uid()));

drop policy if exists "own expenses" on expenses;
create policy "own expenses" on expenses for all
  using (library_id in (select id from libraries where owner_id = auth.uid()))
  with check (library_id in (select id from libraries where owner_id = auth.uid()));

drop policy if exists "own taxes" on taxes;
create policy "own taxes" on taxes for all
  using (library_id in (select id from libraries where owner_id = auth.uid()))
  with check (library_id in (select id from libraries where owner_id = auth.uid()));

drop policy if exists "own invoices" on invoices;
create policy "own invoices" on invoices for all
  using (library_id in (select id from libraries where owner_id = auth.uid()))
  with check (library_id in (select id from libraries where owner_id = auth.uid()));

-- Referrals are cross-tenant: the referred user creates the row; the referrer
-- (matched by their library's referral_code) can read it.
drop policy if exists "ref select" on referrals;
create policy "ref select" on referrals for select using (
  referrer_code in (select referral_code from libraries where owner_id = auth.uid())
  or referred_library_id in (select id from libraries where owner_id = auth.uid())
);

drop policy if exists "ref insert" on referrals;
create policy "ref insert" on referrals for insert with check (
  referred_library_id in (select id from libraries where owner_id = auth.uid())
);

drop policy if exists "ref update" on referrals;
create policy "ref update" on referrals for update using (
  referred_library_id in (select id from libraries where owner_id = auth.uid())
);

-- =====================================================================
-- Storage bucket for member photos & documents (safe to re-run)
-- =====================================================================
insert into storage.buckets (id, name, public)
values ('member-media', 'member-media', true)
on conflict (id) do nothing;

drop policy if exists "member-media read" on storage.objects;
create policy "member-media read" on storage.objects
  for select using (bucket_id = 'member-media');

drop policy if exists "member-media insert" on storage.objects;
create policy "member-media insert" on storage.objects
  for insert to authenticated with check (bucket_id = 'member-media');

drop policy if exists "member-media update" on storage.objects;
create policy "member-media update" on storage.objects
  for update to authenticated using (bucket_id = 'member-media');

drop policy if exists "member-media delete" on storage.objects;
create policy "member-media delete" on storage.objects
  for delete to authenticated using (bucket_id = 'member-media');
