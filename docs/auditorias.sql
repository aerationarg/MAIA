-- MAIA · Auditorías internas de áreas (SGI, formulario F-SGI-38)
-- Correr una sola vez en Supabase → SQL Editor. Es seguro repetirlo.

create table if not exists auditorias_internas (
  id uuid primary key default gen_random_uuid(),
  empresa text not null,
  -- quién audita a quién (lo define SGI)
  area_auditada text not null,
  area_auditora text,
  auditor_id uuid,
  auditor_nombre text,
  programada_por_nombre text,
  fecha_prevista date,
  -- datos generales
  responsable_area text,
  fecha date,
  horario text,
  lugar text,
  alcance text,
  -- checklist: [{base:boolean, pregunta, evidencia, resultado:'C'|'NC'|'O'|'NA'|'', comentario}]
  checklist jsonb default '[]'::jsonb,
  -- resumen, conclusión y cierre
  resp_carga_nombre text,
  fecha_carga date,
  conclusion text,
  autonomia text,                       -- 'Sí' | 'Con acompañamiento' | 'Aún no'
  -- flujo: programada → en_curso → enviada → aprobada (o ajuste → vuelve al auditor)
  estado text default 'programada',
  revision text,                        -- 'Conforme' | 'Requiere ajuste'
  revision_comentario text,
  revisado_por_nombre text,
  revisado_at timestamptz,
  -- registro guardado en la carpeta de Calidad de SharePoint: {ruta, nombre, web_url, pdf, at}
  registro jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists auditorias_internas_empresa_idx on auditorias_internas (empresa, created_at desc);
create index if not exists auditorias_internas_auditor_idx on auditorias_internas (auditor_id);

alter table auditorias_internas enable row level security;
drop policy if exists "auditorias_internas_authenticated_all" on auditorias_internas;
create policy "auditorias_internas_authenticated_all" on auditorias_internas for all to authenticated using (true) with check (true);
