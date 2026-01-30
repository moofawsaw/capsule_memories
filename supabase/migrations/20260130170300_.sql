-- Upload the logo to Supabase storage and update branding config
-- First, let's update to use a Supabase storage path that will work after we upload

-- For now, update to use the existing app icon as fallback until the white logo is uploaded via CMS
UPDATE app_settings 
SET value = jsonb_set(
  value::jsonb, 
  '{emailLogoUrl}', 
  (value::jsonb->'appIconUrl')
),
updated_at = now()
WHERE key = 'branding_config'
AND value::jsonb->>'appIconUrl' IS NOT NULL;;
