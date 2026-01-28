-- Migration: User tag colors
-- Adds a color_hex column for per-tag UI coloring.

ALTER TABLE public.user_tags
ADD COLUMN IF NOT EXISTS color_hex TEXT NOT NULL DEFAULT '#8B5CF6';

COMMENT ON COLUMN public.user_tags.color_hex IS
  'Hex color for this user tag (e.g. #8B5CF6).';

