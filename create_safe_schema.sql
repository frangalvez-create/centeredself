-- Safe Supabase Schema for Centered App
-- Run this in your Supabase SQL Editor

-- Create user_profiles table
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    display_name TEXT,
    first_name TEXT,
    last_name TEXT,
    gender TEXT,
    occupation TEXT,
    birthdate TEXT,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    total_journal_entries INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    -- Subscription fields
    is_premium BOOLEAN DEFAULT FALSE,
    subscription_status TEXT DEFAULT 'free',
    subscription_expires_at TIMESTAMPTZ,
    revenuecat_user_id TEXT,
    subscription_updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create journal_entries table
CREATE TABLE IF NOT EXISTS public.journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    goal TEXT,
    question_text TEXT,
    ai_response TEXT,
    is_favorite BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create goals table
CREATE TABLE IF NOT EXISTS public.goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create guided_questions table
CREATE TABLE IF NOT EXISTS public.guided_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_text TEXT NOT NULL,
    category TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add missing columns to existing tables (if they don't exist)
DO $$ 
BEGIN
    -- Add subscription fields to user_profiles if they don't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'is_premium') THEN
        ALTER TABLE public.user_profiles ADD COLUMN is_premium BOOLEAN DEFAULT FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'subscription_status') THEN
        ALTER TABLE public.user_profiles ADD COLUMN subscription_status TEXT DEFAULT 'free';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'subscription_expires_at') THEN
        ALTER TABLE public.user_profiles ADD COLUMN subscription_expires_at TIMESTAMPTZ;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'revenuecat_user_id') THEN
        ALTER TABLE public.user_profiles ADD COLUMN revenuecat_user_id TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'subscription_updated_at') THEN
        ALTER TABLE public.user_profiles ADD COLUMN subscription_updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
    
    -- Add missing fields to user_profiles if they don't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'first_name') THEN
        ALTER TABLE public.user_profiles ADD COLUMN first_name TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'last_name') THEN
        ALTER TABLE public.user_profiles ADD COLUMN last_name TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'gender') THEN
        ALTER TABLE public.user_profiles ADD COLUMN gender TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'occupation') THEN
        ALTER TABLE public.user_profiles ADD COLUMN occupation TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'birthdate') THEN
        ALTER TABLE public.user_profiles ADD COLUMN birthdate TEXT;
    END IF;
    
    -- Add missing fields to journal_entries if they don't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'journal_entries' AND column_name = 'goal') THEN
        ALTER TABLE public.journal_entries ADD COLUMN goal TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'journal_entries' AND column_name = 'question_text') THEN
        ALTER TABLE public.journal_entries ADD COLUMN question_text TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'journal_entries' AND column_name = 'ai_response') THEN
        ALTER TABLE public.journal_entries ADD COLUMN ai_response TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'journal_entries' AND column_name = 'is_favorite') THEN
        ALTER TABLE public.journal_entries ADD COLUMN is_favorite BOOLEAN DEFAULT FALSE;
    END IF;
    
    -- Add missing fields to goals if they don't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'goals' AND column_name = 'is_completed') THEN
        ALTER TABLE public.goals ADD COLUMN is_completed BOOLEAN DEFAULT FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'goals' AND column_name = 'description') THEN
        ALTER TABLE public.goals ADD COLUMN description TEXT;
    END IF;
    
END $$;

-- Insert sample guided questions (only if table is empty)
INSERT INTO public.guided_questions (question_text, category) 
SELECT * FROM (VALUES
    ('What are you most grateful for today?', 'gratitude'),
    ('What was the highlight of your day?', 'reflection'),
    ('What challenge did you overcome today?', 'growth'),
    ('How did you show kindness to yourself or others today?', 'kindness'),
    ('What did you learn about yourself today?', 'self-discovery'),
    ('What would you like to improve about tomorrow?', 'improvement'),
    ('What made you smile today?', 'positivity'),
    ('How did you take care of your mental health today?', 'wellness'),
    ('What are you looking forward to?', 'future'),
    ('What are you proud of accomplishing today?', 'achievement')
) AS v(question_text, category)
WHERE NOT EXISTS (SELECT 1 FROM public.guided_questions);

-- Create indexes for better performance (only if they don't exist)
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON public.user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_journal_entries_user_id ON public.journal_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_journal_entries_created_at ON public.journal_entries(created_at);
CREATE INDEX IF NOT EXISTS idx_goals_user_id ON public.goals(user_id);
CREATE INDEX IF NOT EXISTS idx_goals_is_completed ON public.goals(is_completed);

-- Enable Row Level Security (RLS)
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guided_questions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can view own journal entries" ON public.journal_entries;
DROP POLICY IF EXISTS "Users can insert own journal entries" ON public.journal_entries;
DROP POLICY IF EXISTS "Users can update own journal entries" ON public.journal_entries;
DROP POLICY IF EXISTS "Users can delete own journal entries" ON public.journal_entries;
DROP POLICY IF EXISTS "Users can view own goals" ON public.goals;
DROP POLICY IF EXISTS "Users can insert own goals" ON public.goals;
DROP POLICY IF EXISTS "Users can update own goals" ON public.goals;
DROP POLICY IF EXISTS "Users can delete own goals" ON public.goals;
DROP POLICY IF EXISTS "Anyone can view guided questions" ON public.guided_questions;

-- Create RLS policies for user_profiles
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = user_id);

-- Create RLS policies for journal_entries
CREATE POLICY "Users can view own journal entries" ON public.journal_entries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own journal entries" ON public.journal_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own journal entries" ON public.journal_entries
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own journal entries" ON public.journal_entries
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for goals
CREATE POLICY "Users can view own goals" ON public.goals
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own goals" ON public.goals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own goals" ON public.goals
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own goals" ON public.goals
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for guided_questions (public read access)
CREATE POLICY "Anyone can view guided questions" ON public.guided_questions
    FOR SELECT USING (true);

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
