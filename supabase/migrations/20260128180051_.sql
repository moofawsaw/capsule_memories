-- Create table for system message templates
CREATE TABLE public.system_messages (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  image_url TEXT,
  is_draft BOOLEAN DEFAULT true,
  sent_at TIMESTAMP WITH TIME ZONE,
  sent_to_count INTEGER,
  target_audience TEXT DEFAULT 'all', -- 'all', 'verified', 'active'
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  created_by UUID REFERENCES auth.users(id),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.system_messages ENABLE ROW LEVEL SECURITY;

-- Admin-only policies
CREATE POLICY "Admins can view all system messages"
  ON public.system_messages FOR SELECT
  USING (EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role IN ('admin', 'moderator')));

CREATE POLICY "Admins can create system messages"
  ON public.system_messages FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role IN ('admin', 'moderator')));

CREATE POLICY "Admins can update system messages"
  ON public.system_messages FOR UPDATE
  USING (EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role IN ('admin', 'moderator')));

CREATE POLICY "Admins can delete system messages"
  ON public.system_messages FOR DELETE
  USING (EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role IN ('admin', 'moderator')));

-- Add index for efficient querying
CREATE INDEX idx_system_messages_created_at ON public.system_messages(created_at DESC);
CREATE INDEX idx_system_messages_is_draft ON public.system_messages(is_draft);;
