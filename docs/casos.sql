-- MAIA · Casos (mesa de trabajo de Procesos con IA)
-- Correr una sola vez en Supabase → SQL Editor.

create table if not exists maia_casos (
  id uuid primary key default gen_random_uuid(),
  empresa text not null,
  nombre text not null,
  cliente text,
  estado text default 'activo',
  resumen text default '',
  vinculos jsonb default '[]'::jsonb,
  notas jsonb default '[]'::jsonb,
  creado_por_nombre text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists maia_casos_mensajes (
  id uuid primary key default gen_random_uuid(),
  caso_id uuid not null references maia_casos(id) on delete cascade,
  empresa text not null,
  rol text not null,
  contenido text not null default '',
  meta jsonb default '{}'::jsonb,
  autor text,
  costo_usd numeric default 0,
  created_at timestamptz default now()
);

create index if not exists maia_casos_empresa_idx on maia_casos (empresa, updated_at desc);
create index if not exists maia_casos_mensajes_caso_idx on maia_casos_mensajes (caso_id, created_at);
create index if not exists maia_casos_mensajes_empresa_idx on maia_casos_mensajes (empresa, created_at);

alter table maia_casos enable row level security;
alter table maia_casos_mensajes enable row level security;

drop policy if exists "maia_casos_authenticated_all" on maia_casos;
create policy "maia_casos_authenticated_all" on maia_casos for all to authenticated using (true) with check (true);
drop policy if exists "maia_casos_mensajes_authenticated_all" on maia_casos_mensajes;
create policy "maia_casos_mensajes_authenticated_all" on maia_casos_mensajes for all to authenticated using (true) with check (true);

-- ── Recetas de Casos (pedidos guardados que se eligen escribiendo "/" en el chat) ──
-- Si ya corriste lo anterior, corré solo este bloque.
create table if not exists maia_casos_recetas (
  id uuid primary key default gen_random_uuid(),
  empresa text not null,
  nombre text not null,
  descripcion text default '',
  instrucciones text not null,
  creado_por_nombre text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
create index if not exists maia_casos_recetas_empresa_idx on maia_casos_recetas (empresa, nombre);
alter table maia_casos_recetas enable row level security;
drop policy if exists "maia_casos_recetas_authenticated_all" on maia_casos_recetas;
create policy "maia_casos_recetas_authenticated_all" on maia_casos_recetas for all to authenticated using (true) with check (true);
