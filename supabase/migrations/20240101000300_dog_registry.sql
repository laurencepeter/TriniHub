-- Dog registration workflow tables.
-- (Originally supabase_dog_schema.sql. RLS policies live in a later migration.)

create extension if not exists "uuid-ossp";

create table if not exists trinihub.regions (
    id uuid primary key default uuid_generate_v4(),
    name text not null
);

create table if not exists trinihub.breeds (
    id uuid primary key default uuid_generate_v4(),
    name text not null
);

create table if not exists trinihub.owners (
    id uuid primary key default uuid_generate_v4(),
    auth_user_id uuid not null references auth.users(id) on delete cascade,
    first_name text not null,
    last_name text not null,
    phone text,
    email text,
    national_id text,
    address_line1 text,
    address_line2 text,
    region_id uuid references trinihub.regions(id) on delete set null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create unique index if not exists owners_auth_user_id_key on trinihub.owners (auth_user_id);

create table if not exists trinihub.dogs (
    id uuid primary key default uuid_generate_v4(),
    dog_number text not null,
    name text,
    sex text not null default 'unknown',
    breed_id uuid references trinihub.breeds(id) on delete set null,
    color text,
    dob date,
    microchip_id text,
    status text not null default 'active',
    life_status text not null default 'alive',
    current_owner_id uuid not null references trinihub.owners(id) on delete restrict,
    notes text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create unique index if not exists dogs_dog_number_key on trinihub.dogs (dog_number);

create table if not exists trinihub.dog_ownerships (
    id uuid primary key default uuid_generate_v4(),
    dog_id uuid not null references trinihub.dogs(id) on delete cascade,
    owner_id uuid not null references trinihub.owners(id) on delete cascade,
    start_date date not null default current_date,
    created_at timestamptz not null default now()
);
