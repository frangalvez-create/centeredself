DROP TABLE IF EXISTS journal_sessions CASCADE;

ALTER TABLE journal_entries DROP COLUMN IF EXISTS entry_type;
ALTER TABLE journal_entries DROP COLUMN IF EXISTS ai_prompt;
ALTER TABLE journal_entries DROP COLUMN IF EXISTS ai_response;
ALTER TABLE journal_entries DROP COLUMN IF EXISTS tags;
ALTER TABLE journal_entries DROP COLUMN IF EXISTS guided_question_id;

ALTER TABLE guided_questions DROP COLUMN IF EXISTS order_index;

DROP INDEX IF EXISTS idx_journal_entries_user_id;
DROP INDEX IF EXISTS idx_journal_entries_guided_question_id;
DROP INDEX IF EXISTS idx_journal_entries_entry_type;
DROP INDEX IF EXISTS idx_journal_sessions_user_id;
DROP INDEX IF EXISTS idx_journal_sessions_date;
