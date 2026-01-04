-- Add group_id column to memories table to track which group created the memory
ALTER TABLE memories 
ADD COLUMN group_id uuid REFERENCES groups(id) ON DELETE SET NULL;

-- Create index for better query performance
CREATE INDEX idx_memories_group_id ON memories(group_id);

-- Add comment for documentation
COMMENT ON COLUMN memories.group_id IS 'References the group that created this memory, if applicable';