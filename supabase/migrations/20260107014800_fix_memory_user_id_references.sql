-- Migration: Validate schema and ensure all code uses memories.creator_id (not user_id)
-- The memories table has creator_id column, never had user_id
-- This migration validates the schema and provides helpful error messages

-- 1. Verify that creator_id exists and user_id does not exist
DO $$ 
BEGIN
  -- Check if user_id column exists (it shouldn't)
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'memories' 
    AND column_name = 'user_id'
  ) THEN
    RAISE EXCEPTION 'ERROR: memories.user_id column exists but should be creator_id!';
  END IF;

  -- Verify creator_id exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'memories' 
    AND column_name = 'creator_id'
  ) THEN
    RAISE EXCEPTION 'ERROR: memories.creator_id column does not exist!';
  END IF;

  RAISE NOTICE 'SUCCESS: memories table has correct column structure (creator_id exists, user_id does not)';
END $$;

-- 2. Validate RLS policies reference creator_id correctly
-- FIXED: Use pg_policies.qual instead of non-existent .definition column
-- qual = USING clause (what rows users can see)
-- with_check = WITH CHECK clause (what rows users can insert/update)
DO $$
DECLARE
  policy_record RECORD;
  policy_expr TEXT;
BEGIN
  FOR policy_record IN 
    SELECT 
      schemaname, 
      tablename, 
      policyname, 
      COALESCE(qual::text, '') as using_clause,
      COALESCE(with_check::text, '') as check_clause
    FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'memories'
  LOOP
    -- Concatenate both USING and WITH CHECK clauses for validation
    policy_expr := policy_record.using_clause || ' ' || policy_record.check_clause;
    
    -- Check if policy references non-existent user_id column
    IF policy_expr ILIKE '%memories.user_id%' OR policy_expr ILIKE '%m.user_id%' THEN
      RAISE EXCEPTION 'POLICY ERROR: Policy "%" on table "memories" references non-existent user_id column. Policy expression: %', 
        policy_record.policyname, policy_expr;
    END IF;
    
    RAISE NOTICE 'VALIDATED: Policy "%" uses correct column references', policy_record.policyname;
  END LOOP;
  
  RAISE NOTICE 'SUCCESS: All RLS policies on memories table use correct column references';
END $$;

-- 3. Verify security helper functions use creator_id
DO $$
DECLARE
  func_record RECORD;
  func_body TEXT;
BEGIN
  FOR func_record IN 
    SELECT proname, pg_get_functiondef(oid) as funcdef
    FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
    AND proname IN ('is_memory_creator', 'can_access_memory', 'is_contributor_to_memory')
  LOOP
    func_body := func_record.funcdef;
    
    -- Check if function references non-existent user_id column
    IF func_body ILIKE '%memories.user_id%' OR func_body ILIKE '%m.user_id%' THEN
      RAISE EXCEPTION 'FUNCTION ERROR: Function "%" references non-existent user_id column in memories table. Function body: %', 
        func_record.proname, func_body;
    END IF;
    
    RAISE NOTICE 'VALIDATED: Function "%" uses correct column references', func_record.proname;
  END LOOP;
  
  RAISE NOTICE 'SUCCESS: All security functions use correct column references (creator_id)';
END $$;

-- 4. Add helpful comment to memories.creator_id column
COMMENT ON COLUMN public.memories.creator_id IS 
  '⚠️ CRITICAL: This is the user who created the memory. ALWAYS use creator_id, NEVER user_id (which does not exist).';

-- 5. Success confirmation
DO $$
BEGIN
  RAISE NOTICE '✅ MIGRATION COMPLETE: Schema validation successful';
  RAISE NOTICE '   ✓ memories.creator_id column exists and is properly referenced';
  RAISE NOTICE '   ✓ memories.user_id column does NOT exist (correct)';
  RAISE NOTICE '   ✓ All RLS policies validated';
  RAISE NOTICE '   ✓ All security functions validated';
  RAISE NOTICE '';
  RAISE NOTICE '📌 IMPORTANT: Application code must use memories.creator_id';
  RAISE NOTICE '   - NEVER select, filter, or join on memories.user_id';
  RAISE NOTICE '   - ALWAYS use memories.creator_id for ownership checks';
  RAISE NOTICE '   - Update any Dart/Flutter code querying memories.user_id';
END $$;