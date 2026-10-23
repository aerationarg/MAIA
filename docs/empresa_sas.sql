-- Entorno nuevo SAS (Aeration Uruguay) — chequeo en Supabase.
-- MAIA usa la columna "empresa" (AA / AS / ahora SAS) en casi todas las tablas, y "profiles.empresas" (texto: 'AA,AS,SAS') para saber a qué empresas entra cada usuario.
-- Si alguna tabla tiene una restricción (CHECK) o una política (RLS) escrita solo para 'AA' y 'AS', SAS va a fallar al guardar. Estas consultas son SOLO de lectura:
-- corrélas en el SQL Editor de Supabase y pasame lo que devuelvan (si no devuelven filas, no hay nada que arreglar).

-- 1) Restricciones CHECK que nombran 'AS' (candidatas a bloquear 'SAS')
select conrelid::regclass as tabla, conname as restriccion, pg_get_constraintdef(oid) as definicion
from pg_constraint
where contype = 'c' and pg_get_constraintdef(oid) ilike '%''AS''%';

-- 2) Políticas de seguridad (RLS) que nombran 'AS'
select schemaname, tablename, policyname, cmd, qual, with_check
from pg_policies
where coalesce(qual, '') ilike '%''AS''%' or coalesce(with_check, '') ilike '%''AS''%';

-- 3) Tipos enumerados con 'AS' como valor
select t.typname as tipo, e.enumlabel as valor
from pg_type t join pg_enum e on e.enumtypid = t.oid
where t.typname ilike '%empresa%' or e.enumlabel = 'AS';

-- ─────────────────────────────────────────────────────────────────────────────
-- RESULTADO DEL CHEQUEO (23/10/2026): la consulta 1 encontró UNA restricción que solo admite AA y AS:
--   conciliacion_bancos.conciliacion_bancos_empresa_check → CHECK (empresa = ANY (ARRAY['AA','AS']))
-- Las consultas 2 y 3 (políticas RLS y tipos enumerados) no devolvieron nada. Para poder cargar bancos de SAS en Conciliación bancaria, correr esto UNA vez:
alter table conciliacion_bancos drop constraint if exists conciliacion_bancos_empresa_check;
alter table conciliacion_bancos add constraint conciliacion_bancos_empresa_check check (empresa = any (array['AA'::text, 'AS'::text, 'SAS'::text]));
