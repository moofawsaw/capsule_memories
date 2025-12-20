-- Create private bucket for user avatars
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars', 
    false,
    5242880,
    ARRAY['image/jpeg', 'image/png', 'image/webp']
);

-- RLS: Users can only manage their own avatar files
CREATE POLICY "users_manage_own_avatars" ON storage.objects
FOR ALL TO authenticated
USING (bucket_id = 'avatars' AND owner = auth.uid())
WITH CHECK (bucket_id = 'avatars' AND owner = auth.uid());