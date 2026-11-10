-- MAIA · Restablecer la contraseña de otra persona (solo Admin)
-- Hace falta para el botón "Restablecer contraseña" de Admin › Gestión de usuarios.
-- Crea la función public.admin_reset_password(p_user_id, p_password). Solo la puede ejecutar un usuario logueado cuyo sector en profiles sea 'Admin'
-- (la propia función lo verifica). Guarda la contraseña ya cifrada (bcrypt), igual que Supabase Auth, y cierra las sesiones abiertas de esa persona.
-- Es seguro repetirlo.

create extension if not exists pgcrypto with schema extensions;

create or replace function public.admin_reset_password(p_user_id uuid, p_password text)
returns void
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
begin
  if not exists (select 1 from public.profiles where id = auth.uid() and sector = 'Admin') then
    raise exception 'Solo un Admin puede restablecer contraseñas.';
  end if;
  if p_password is null or length(p_password) < 6 then
    raise exception 'La contraseña debe tener al menos 6 caracteres.';
  end if;
  update auth.users
     set encrypted_password = extensions.crypt(p_password, extensions.gen_salt('bf')),
         updated_at = now()
   where id = p_user_id;
  if not found then
    raise exception 'No existe ese usuario.';
  end if;
  -- cierra las sesiones abiertas de esa persona (si la tabla existe en esta versión de Supabase)
  begin
    delete from auth.sessions where user_id = p_user_id;
  exception when others then
    null;
  end;
end;
$$;

revoke all on function public.admin_reset_password(uuid, text) from public, anon;
grant execute on function public.admin_reset_password(uuid, text) to authenticated;
