-- Complete Database Cleanup Script
-- This script removes ALL subscription/tier related code and data
-- and provides a completely fresh start

-- Step 1: Drop all premium/subscription related tables
DO $$ 
BEGIN
    -- Drop tables if they exist
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'daily_sessions') THEN
        DROP TABLE daily_sessions CASCADE;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'subscription_history') THEN
        DROP TABLE subscription_history CASCADE;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'premium_questions') THEN
        DROP TABLE premium_questions CASCADE;
    END IF;
END $$;

-- Step 2: Drop all premium/subscription related functions
DROP FUNCTION IF EXISTS get_todays_session(user_id UUID);
DROP FUNCTION IF EXISTS can_complete_question(user_id UUID, question_type TEXT);
DROP FUNCTION IF EXISTS get_todays_guided_question(user_id UUID);
DROP FUNCTION IF EXISTS mark_question_completed(user_id UUID, question_type TEXT);
DROP FUNCTION IF EXISTS upgrade_to_premium(user_id UUID, price DECIMAL);
DROP FUNCTION IF EXISTS get_user_subscription_status(user_id UUID);

-- Step 3: Drop all premium/subscription related triggers
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'update_daily_session_trigger') THEN
        EXECUTE 'DROP TRIGGER update_daily_session_trigger ON journal_entries';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'reset_daily_sessions_trigger') THEN
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'daily_sessions') THEN
            EXECUTE 'DROP TRIGGER reset_daily_sessions_trigger ON daily_sessions';
        END IF;
    END IF;
END $$;

-- Step 4: Remove ALL subscription/tier related columns from user_profiles
DO $$ 
BEGIN
    -- Remove subscription columns if they exist
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
END $$;

-- Step 5: Remove ALL premium question related columns from journal_entries
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'journal_entries' AND column_name = 'question_type') THEN
        ALTER TABLE journal_entries DROP COLUMN question_type;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'journal_entries' AND column_name = 'entry_date') THEN
        ALTER TABLE journal_entries DROP COLUMN entry_date;
    END IF;
END $$;

-- Step 6: DELETE ALL existing users and their data
-- WARNING: This will delete ALL user data permanently
DELETE FROM journal_entries;
DELETE FROM goals;
DELETE FROM user_profiles;

-- Step 7: Clear any remaining premium question data
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'journal_entries' AND column_name = 'question_type') THEN
        DELETE FROM journal_entries WHERE question_type IS NOT NULL;
    END IF;
END $$;

-- Step 8: Reset sequences (if they exist)
DO $$
BEGIN
    -- Reset user_profiles sequence
    IF EXISTS (SELECT 1 FROM information_schema.sequences WHERE sequence_name = 'user_profiles_id_seq') THEN
        ALTER SEQUENCE user_profiles_id_seq RESTART WITH 1;
    END IF;
    
    -- Reset journal_entries sequence
    IF EXISTS (SELECT 1 FROM information_schema.sequences WHERE sequence_name = 'journal_entries_id_seq') THEN
        ALTER SEQUENCE journal_entries_id_seq RESTART WITH 1;
    END IF;
    
    -- Reset goals sequence
    IF EXISTS (SELECT 1 FROM information_schema.sequences WHERE sequence_name = 'goals_id_seq') THEN
        ALTER SEQUENCE goals_id_seq RESTART WITH 1;
    END IF;
END $$;

-- Step 9: Verify the cleanup
SELECT 'Database completely cleaned - all subscription/tier code removed and all user data deleted' as status;

-- Step 10: Show current schema
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name IN ('user_profiles', 'journal_entries', 'goals')
ORDER BY table_name, ordinal_position;
