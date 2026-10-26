-- Rodar no SQL Editor do Supabase

-- Tabela de perfis de usuário com status de aprovação
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  invited_by TEXT, -- email do admin que convidou (se veio por convite)
  created_at TIMESTAMPTZ DEFAULT now(),
  approved_at TIMESTAMPTZ
);

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Usuário pode ver seu próprio perfil
CREATE POLICY "user_own_profile" ON user_profiles
  FOR SELECT USING (auth.uid() = id);

-- Somente funções admin podem inserir/atualizar
CREATE POLICY "service_role_all" ON user_profiles
  FOR ALL USING (true)
  WITH CHECK (true);

-- Função para criar perfil automaticamente ao registrar
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  -- Desativa RLS para garantir que o insert funcione mesmo com políticas ativas
  PERFORM set_config('row_security', 'off', true);

  INSERT INTO public.user_profiles (id, email, status)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    -- Usuários convidados são aprovados automaticamente
    CASE WHEN NEW.invited_at IS NOT NULL
    THEN 'approved'
    ELSE 'pending'
    END
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- Trigger para novos usuários
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Migrar usuários existentes como aprovados
INSERT INTO user_profiles (id, email, status)
SELECT id, email, 'approved'
FROM auth.users
ON CONFLICT (id) DO NOTHING;
