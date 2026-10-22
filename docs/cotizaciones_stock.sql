-- Cotizaciones › Stock: campos nuevos de los artículos.
-- Correr una vez en el SQL Editor de Supabase. Es seguro repetirlo.

-- Observaciones: texto libre. No se ve al buscar ítems en Cotizaciones; sí al insertar el ítem en la cotización.
alter table cotizaciones_catalogo add column if not exists observaciones text;

-- Archivos adjuntos (fichas técnicas, fotos, etc.): lista [{nombre, ruta, mime, tamano}] + bucket privado donde se guardan.
-- Si un ítem de la cotización es de un artículo con archivos, se agregan como anexos al final del PDF.
alter table cotizaciones_catalogo add column if not exists archivos jsonb default '[]'::jsonb;

insert into storage.buckets (id, name, public) values ('cotizaciones-anexos', 'cotizaciones-anexos', false) on conflict (id) do nothing;
drop policy if exists "cotizaciones_anexos_storage_authenticated_all" on storage.objects;
create policy "cotizaciones_anexos_storage_authenticated_all" on storage.objects for all to authenticated
  using (bucket_id = 'cotizaciones-anexos') with check (bucket_id = 'cotizaciones-anexos');
