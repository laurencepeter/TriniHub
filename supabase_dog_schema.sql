-- Schema for the dog registration workflow in Supabase/Postgres.
-- Run this in the Supabase SQL editor before applying supabase_dog_rls_policies.sql.

create extension if not exists "uuid-ossp";

create table if not exists public.regions (
    id uuid primary key default uuid_generate_v4(),
    name text not null
);

create table if not exists public.breeds (
    id uuid primary key default uuid_generate_v4(),
    name text not null
);

create table if not exists public.owners (
    id uuid primary key default uuid_generate_v4(),
    auth_user_id uuid not null references auth.users(id) on delete cascade,
    first_name text not null,
    last_name text not null,
    phone text,
    email text,
    national_id text,
    address_line1 text,
    address_line2 text,
    region_id uuid references public.regions(id) on delete set null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create unique index if not exists owners_auth_user_id_key on public.owners (auth_user_id);

create table if not exists public.dogs (
    id uuid primary key default uuid_generate_v4(),
    dog_number text not null,
    name text,
    sex text not null default 'unknown',
    breed_id uuid references public.breeds(id) on delete set null,
    color text,
    dob date,
    microchip_id text,
    status text not null default 'active',
    current_owner_id uuid not null references public.owners(id) on delete restrict,
    notes text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create unique index if not exists dogs_dog_number_key on public.dogs (dog_number);

create table if not exists public.dog_ownerships (
    id uuid primary key default uuid_generate_v4(),
    dog_id uuid not null references public.dogs(id) on delete cascade,
    owner_id uuid not null references public.owners(id) on delete cascade,
    start_date date not null default current_date,
    created_at timestamptz not null default now()
);
