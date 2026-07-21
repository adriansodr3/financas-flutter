-- Rodar no SQL Editor do Supabase
-- Cria função para retornar tamanho de uma tabela em bytes

CREATE OR REPLACE FUNCTION table_size(table_name text)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  size_bytes bigint;
BEGIN
  SELECT pg_total_relation_size(quote_ident(table_name)) INTO size_bytes;
  RETURN size_bytes;
END;
$$;
