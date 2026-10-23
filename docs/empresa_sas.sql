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
