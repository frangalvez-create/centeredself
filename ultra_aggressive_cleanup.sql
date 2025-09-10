-- Ultra Aggressive Database Cleanup Script
-- This script will remove EVERYTHING subscription-related that might still exist

-- Drop ALL possible subscription-related tables
DROP TABLE IF EXISTS subscription_tiers CASCADE;
DROP TABLE IF EXISTS subscription_history CASCADE;
DROP TABLE IF EXISTS daily_sessions CASCADE;
DROP TABLE IF EXISTS premium_questions CASCADE;
DROP TABLE IF EXISTS user_streaks CASCADE;
DROP TABLE IF EXISTS journal_sessions CASCADE;
DROP TABLE IF EXISTS user_subscriptions CASCADE;
DROP TABLE IF EXISTS subscription_plans CASCADE;
DROP TABLE IF EXISTS billing_history CASCADE;
DROP TABLE IF EXISTS payment_methods CASCADE;

-- Drop ALL possible subscription-related functions
DROP FUNCTION IF EXISTS get_todays_session(user_id UUID);
DROP FUNCTION IF EXISTS can_complete_question(user_id UUID, question_type TEXT);
DROP FUNCTION IF EXISTS get_todays_guided_question(user_id UUID);
DROP FUNCTION IF EXISTS mark_question_completed(user_id UUID, question_type TEXT);
DROP FUNCTION IF EXISTS upgrade_to_premium(user_id UUID, price DECIMAL);
DROP FUNCTION IF EXISTS get_user_subscription_status(user_id UUID);
DROP FUNCTION IF EXISTS increment_journal_entry_count(user_id UUID);
DROP FUNCTION IF EXISTS user_has_premium_access(user_id UUID);
DROP FUNCTION IF EXISTS reset_daily_sessions();
DROP FUNCTION IF EXISTS get_user_tier(user_id UUID);

-- Drop ALL possible subscription-related triggers
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT trigger_name, event_object_table FROM information_schema.triggers WHERE trigger_schema = 'public')
    LOOP
        EXECUTE 'DROP TRIGGER IF EXISTS ' || quote_ident(r.trigger_name) || ' ON ' || quote_ident(r.event_object_table) || ' CASCADE;';
    END LOOP;
END $$;

-- Remove ALL possible subscription-related columns from user_profiles
DO $$
BEGIN
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
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'tier_id') THEN
        ALTER TABLE user_profiles DROP COLUMN tier_id;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'is_premium') THEN
        ALTER TABLE user_profiles DROP COLUMN is_premium;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'premium_status') THEN
        ALTER TABLE user_profiles DROP COLUMN premium_status;
    END IF;
END $$;

-- Remove ALL possible subscription-related columns from journal_entries
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'journal_entries' AND column_name = 'question_type') THEN
        ALTER TABLE journal_entries DROP COLUMN question_type;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'journal_entries' AND column_name = 'entry_date') THEN
        ALTER TABLE journal_entries DROP COLUMN entry_date;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'journal_entries' AND column_name = 'session_id') THEN
        ALTER TABLE journal_entries DROP COLUMN session_id;
    END IF;
END $$;

-- Delete all existing data
DELETE FROM journal_entries;
DELETE FROM goals;
DELETE FROM user_profiles;

-- Reset sequences
ALTER SEQUENCE IF EXISTS user_profiles_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS journal_entries_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS goals_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS guided_questions_id_seq RESTART WITH 1;

-- Verify cleanup
SELECT 'Ultra aggressive cleanup complete. All subscription-related objects should be removed.' as status;

-- Show remaining tables
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;
