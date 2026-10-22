-- Cotizaciones › Stock: campo Observaciones de texto libre en cada artículo.
-- Correr una vez en el SQL Editor de Supabase. Es seguro repetirlo (if not exists).
alter table cotizaciones_catalogo add column if not exists observaciones text;
