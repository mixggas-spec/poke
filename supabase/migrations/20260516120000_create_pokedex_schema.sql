-- Pokedex app: profiles, catalog, user entries, captures + RLS

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null unique,
  created_at timestamptz not null default now()
);

create table public.pokemon_catalog (
  id uuid primary key default gen_random_uuid(),
  pokedex_number integer not null unique,
  name text not null,
  description text,
  image_url text,
  silhouette_url text,
  type_1 text,
  type_2 text,
  pokemon_api_url text,
  created_at timestamptz not null default now()
);

create table public.user_pokedex_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  pokemon_id uuid not null references public.pokemon_catalog (id) on delete cascade,
  is_discovered boolean not null default false,
  discovered_at timestamptz,
  times_scanned integer not null default 0,
  unique (user_id, pokemon_id)
);

create table public.captures (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  pokemon_id uuid not null references public.pokemon_catalog (id) on delete cascade,
  captured_image_url text,
  is_new_discovery boolean not null default false,
  created_at timestamptz not null default now()
);

create index user_pokedex_entries_user_id_idx on public.user_pokedex_entries (user_id);
create index user_pokedex_entries_pokemon_id_idx on public.user_pokedex_entries (pokemon_id);
create index captures_user_id_idx on public.captures (user_id);
create index pokemon_catalog_pokedex_number_idx on public.pokemon_catalog (pokedex_number);

alter table public.profiles enable row level security;
alter table public.pokemon_catalog enable row level security;
alter table public.user_pokedex_entries enable row level security;
alter table public.captures enable row level security;

-- profiles
create policy "profiles_select_own"
  on public.profiles
  for select
  to authenticated
  using (auth.uid() = id);

create policy "profiles_insert_own"
  on public.profiles
  for insert
  to authenticated
  with check (auth.uid() = id);

create policy "profiles_update_own"
  on public.profiles
  for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- pokemon_catalog (read-only for app users)
create policy "pokemon_catalog_select_authenticated"
  on public.pokemon_catalog
  for select
  to authenticated
  using (true);

-- user_pokedex_entries
create policy "user_pokedex_entries_select_own"
  on public.user_pokedex_entries
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "user_pokedex_entries_insert_own"
  on public.user_pokedex_entries
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "user_pokedex_entries_update_own"
  on public.user_pokedex_entries
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- captures
create policy "captures_select_own"
  on public.captures
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "captures_insert_own"
  on public.captures
  for insert
  to authenticated
  with check (auth.uid() = user_id);
