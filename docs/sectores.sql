-- MAIA · Sectores creados desde Admin
-- Solo hace falta si, al asignar un sector nuevo (o renombrar uno) a una persona, MAIA avisa que la base no aceptó el valor.
-- Quita cualquier restricción (check constraint) de profiles que limite los valores de la columna sector. Es seguro repetirlo.

do $$
declare c record;
begin
  for c in
    select conname
    from pg_constraint
    where conrelid = 'public.profiles'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%sector%'
  loop
    execute format('alter table public.profiles drop constraint %I', c.conname);
    raise notice 'Se quitó la restricción %', c.conname;
  end loop;
end $$;
