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

-- RLS: Authenticated users can upload to memory folders (stories/{memory_id}/{filename})
-- This allows uploads to paths like stories/{memory_id}/{filename}
CREATE POLICY "authenticated_upload_story_media" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'story-media' 
  AND (storage.foldername(name))[1] = 'stories'
  AND auth.uid() IS NOT NULL
);

-- RLS: Users can delete their own story files
-- Check if the user is the contributor_id in the stories table for this file
CREATE POLICY "owners_delete_story_media" ON storage.objects
FOR DELETE TO authenticated  
USING (
  bucket_id = 'story-media' 
  AND EXISTS (
    SELECT 1 FROM stories 
    WHERE (stories.video_url LIKE '%' || objects.name || '%' OR stories.image_url LIKE '%' || objects.name || '%')
    AND stories.contributor_id = auth.uid()
  )
);

-- RLS: Users can update their own story files
CREATE POLICY "owners_update_story_media" ON storage.objects
FOR UPDATE TO authenticated
USING (
  bucket_id = 'story-media' 
  AND EXISTS (
    SELECT 1 FROM stories 
    WHERE (stories.video_url LIKE '%' || objects.name || '%' OR stories.image_url LIKE '%' || objects.name || '%')
    AND stories.contributor_id = auth.uid()
  )
)
WITH CHECK (
  bucket_id = 'story-media'
  AND EXISTS (
    SELECT 1 FROM stories 
    WHERE (stories.video_url LIKE '%' || objects.name || '%' OR stories.image_url LIKE '%' || objects.name || '%')
    AND stories.contributor_id = auth.uid()
  )
);