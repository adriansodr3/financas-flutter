-- Rodar no SQL Editor do Supabase

-- 1. Criar bucket para avatares
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Policy: usuário pode fazer upload do próprio avatar
CREATE POLICY "avatar_upload" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- 3. Policy: usuário pode atualizar o próprio avatar
CREATE POLICY "avatar_update" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- 4. Policy: leitura pública (para exibir as fotos)
CREATE POLICY "avatar_public_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

-- 5. Policy: usuário pode deletar o próprio avatar
CREATE POLICY "avatar_delete" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );
