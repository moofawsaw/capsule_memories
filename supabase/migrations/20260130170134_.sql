-- Update branding config to use PNG email logo instead of SVG
UPDATE app_settings 
SET value = jsonb_set(
  value::jsonb, 
  '{emailLogoUrl}', 
  '"https://capsuleapp.lovable.app/images/logo-white.png"'
),
updated_at = now()
WHERE key = 'branding_config';;
