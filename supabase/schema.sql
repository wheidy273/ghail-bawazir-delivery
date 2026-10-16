-- مخطط أولي لقاعدة بيانات تطبيق توصيل غيل باوزير.
-- راجع صلاحيات RLS واختبرها قبل استخدام بيانات حقيقية.

create extension if not exists pgcrypto;

create type public.app_role as enum ('customer', 'merchant', 'courier', 'admin');
create type public.order_status as enum
  ('pending', 'accepted', 'preparing', 'ready', 'picked_up', 'delivered', 'cancelled');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text,
  role public.app_role not null default 'customer',
  created_at timestamptz not null default now()
);

create table public.shops (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references public.profiles(id),
  name text not null,
  category text not null,
  description text,
  address text,
  phone text,
  delivery_fee_yer numeric(12,2) not null default 0,
  commission_percent numeric(5,2) not null default 0,
  is_open boolean not null default false,
  is_approved boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  name text not null,
  description text,
  price_yer numeric(12,2) not null check (price_yer >= 0),
  image_url text,
  is_available boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id),
  shop_id uuid not null references public.shops(id),
  courier_id uuid references public.profiles(id),
  status public.order_status not null default 'pending',
  customer_name text not null,
  customer_phone text not null,
  delivery_address text not null,
  notes text,
  subtotal_yer numeric(12,2) not null check (subtotal_yer >= 0),
  delivery_fee_yer numeric(12,2) not null check (delivery_fee_yer >= 0),
  commission_yer numeric(12,2) not null default 0 check (commission_yer >= 0),
  payment_method text not null default 'cash_on_delivery',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id),
  product_name text not null,
  unit_price_yer numeric(12,2) not null check (unit_price_yer >= 0),
  quantity integer not null check (quantity > 0)
);

-- ملاحظة أمان: فعّل RLS واكتب سياسات دقيقة لكل جدول قبل نشر النظام.
-- لا تضع service_role key داخل تطبيق Flutter.
