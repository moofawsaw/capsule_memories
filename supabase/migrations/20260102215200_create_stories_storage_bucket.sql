-- Create stories storage bucket for video and image uploads
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'story-media',
    'story-media',
    true,  -- PUBLIC for easy access
    52428800, -- 50MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/quicktime', 'video/x-msvideo']
) ON CONFLICT (id) DO NOTHING;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "public_read_story_media" ON storage.objects;
DROP POLICY IF EXISTS "authenticated_upload_story_media" ON storage.objects;
DROP POLICY IF EXISTS "owners_delete_story_media" ON storage.objects;
DROP POLICY IF EXISTS "owners_update_story_media" ON storage.objects;

-- RLS: Anyone can view stories
CREATE POLICY "public_read_story_media" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'story-media');

-- RLS: Authenticated users can upload to their own folder
CREATE POLICY "authenticated_upload_story_media" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'story-media' AND (storage.foldername(name))[1] = auth.uid()::text);

-- RLS: Users can delete their own files
CREATE POLICY "owners_delete_story_media" ON storage.objects
FOR DELETE TO authenticated  
USING (bucket_id = 'story-media' AND (storage.foldername(name))[1] = auth.uid()::text);

-- RLS: Users can update their own files
CREATE POLICY "owners_update_story_media" ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'story-media' AND (storage.foldername(name))[1] = auth.uid()::text)
WITH CHECK (bucket_id = 'story-media' AND (storage.foldername(name))[1] = auth.uid()::text);