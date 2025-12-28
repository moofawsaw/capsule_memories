-- Migration: Add start_time and end_time columns to memories table
-- Purpose: Enable timeline positioning for stories within a memory's duration

-- Add start_time and end_time columns in a single ALTER TABLE statement
ALTER TABLE memories
ADD COLUMN start_time TIMESTAMP WITH TIME ZONE,
ADD COLUMN end_time TIMESTAMP WITH TIME ZONE;

-- Add indexes for efficient querying
CREATE INDEX idx_memories_start_time ON memories(start_time);
CREATE INDEX idx_memories_end_time ON memories(end_time);

-- Add comment explaining the columns
COMMENT ON COLUMN memories.start_time IS 'Actual event start timestamp for timeline positioning';
COMMENT ON COLUMN memories.end_time IS 'Actual event end timestamp for timeline positioning';

-- Backfill existing memories with reasonable defaults
-- Use created_at as start_time and expires_at as end_time for existing records
UPDATE memories
SET 
  start_time = created_at,
  end_time = expires_at
WHERE start_time IS NULL OR end_time IS NULL;

-- Optional: Make columns NOT NULL after backfill (uncomment if desired)
-- ALTER TABLE memories ALTER COLUMN start_time SET NOT NULL;
-- ALTER TABLE memories ALTER COLUMN end_time SET NOT NULL;