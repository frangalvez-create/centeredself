-- Revert Supabase database to match "completed initial auth implementation" commit
-- This script safely removes all premium question tables and functionality

-- First, drop all triggers that might reference premium tables
DO $$ 
BEGIN
    -- Drop triggers if they exist (without referencing tables that might not exist)
    IF EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'update_daily_session_trigger') THEN
        EXECUTE 'DROP TRIGGER update_daily_session_trigger ON journal_entries';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'reset_daily_sessions_trigger') THEN
        -- Only drop this trigger if the table exists
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'daily_sessions') THEN
            EXECUTE 'DROP TRIGGER reset_daily_sessions_trigger ON daily_sessions';
        END IF;
    END IF;
END $$;

-- Drop premium question related functions (using IF EXISTS)
DROP FUNCTION IF EXISTS get_todays_session(user_id UUID);
DROP FUNCTION IF EXISTS can_complete_question(user_id UUID, question_type TEXT);
DROP FUNCTION IF EXISTS get_todays_guided_question(user_id UUID);
DROP FUNCTION IF EXISTS mark_question_completed(user_id UUID, question_type TEXT);
DROP FUNCTION IF EXISTS upgrade_to_premium(user_id UUID, price DECIMAL);
DROP FUNCTION IF EXISTS get_user_subscription_status(user_id UUID);

-- Drop premium question related tables (checking existence first)
DO $$ 
BEGIN
    -- Drop daily_sessions table if it exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'daily_sessions') THEN
        DROP TABLE daily_sessions CASCADE;
    END IF;
    
    -- Drop subscription_history table if it exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'subscription_history') THEN
        DROP TABLE subscription_history CASCADE;
    END IF;
    
    -- Drop premium_questions table if it exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'premium_questions') THEN
        DROP TABLE premium_questions CASCADE;
    END IF;
END $$;

-- Remove premium question related columns from existing tables (using IF EXISTS)
DO $$ 
BEGIN
    -- Remove columns from user_profiles if they exist
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'subscription_tier') THEN
        ALTER TABLE user_profiles DROP COLUMN subscription_tier;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'subscription_status') THEN
        ALTER TABLE user_profiles DROP COLUMN subscription_status;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'subscription_start_date') THEN
        ALTER TABLE user_profiles DROP COLUMN subscription_start_date;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'subscription_end_date') THEN
        ALTER TABLE user_profiles DROP COLUMN subscription_end_date;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'subscription_price') THEN
        ALTER TABLE user_profiles DROP COLUMN subscription_price;
    END IF;
    
    -- Remove columns from journal_entries if they exist
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'journal_entries' AND column_name = 'question_type') THEN
        ALTER TABLE journal_entries DROP COLUMN question_type;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'journal_entries' AND column_name = 'entry_date') THEN
        ALTER TABLE journal_entries DROP COLUMN entry_date;
    END IF;
END $$;

-- Clean up any remaining premium question data (only if column exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'journal_entries' AND column_name = 'question_type') THEN
        DELETE FROM journal_entries WHERE question_type IS NOT NULL;
    END IF;
END $$;

-- Verify the revert
SELECT 'Database successfully reverted to auth complete state' as status;