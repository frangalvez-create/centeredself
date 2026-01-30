# Guided Questions – New Interleaved Order (Proposal)

**Goal:** Keep using `order_index` in the DB, but reassign it so topics are spread across the 24-day cycle and the same topic rarely appears on consecutive days.

**Current grouping (simplified):** Gratitude/reflection (1–3, 6–7), dreams (4), productivity/time (5, 10, 12, 17, 20), joy/leisure (8, 9, 24), relationships (11), coping/adversity (14, 22), health (15), mindset (16), spiritual (18), gratitude/luck (13, 19), outdoors (21), learning (23).

**Method:** Questions were grouped by topic, then ordered in a round-robin so each day gets a different topic where possible.

---

## Proposed new order (new `order_index` 1–24)

| New order_index | Question text (for verification) |
|-----------------|-----------------------------------|
| 1 | What thing, person or moment filled you with gratitude today? |
| 2 | What went well today and why? |
| 3 | If you dream, what would you like to dream about tonight? |
| 4 | How was your time management today? Anything to improve? |
| 5 | What purchase, under $100, gave you the most joy this month? |
| 6 | Relationshipwise, which is going well or which needs more attention? |
| 7 | How have you handled criticism recently? Positively or Negatively? |
| 8 | What progress have you made recently towards your health? |
| 9 | How has your mindset been recently? Fixed or Growth minded? |
| 10 | When was your last meditative/spiritual moment? How did you feel? |
| 11 | When was the last time you were outdoors? What was enjoyable about it? |
| 12 | What is something new you learned today? |
| 13 | Who is a person in your life you are grateful for? Why? |
| 14 | How are you feeling today? Mind and body |
| 15 | What's your top goal for the next month? |
| 16 | What is your "go-to" book, movie or show? Why? |
| 17 | What was your most recent failure? Where you able to bounce back? |
| 18 | What is something you feel lucky to have in your life? |
| 19 | Were you satisfied with what you accomplished today? |
| 20 | Name an obstacle to your goals… Why is it hindering you? |
| 21 | What is a consistent and reliable source of joy for you? |
| 22 | What are you looking forward to tomorrow? |
| 23 | Are you tracking your progress towards your goals? How's it going? |
| 24 | Are you feeling overall stagnant or are you progressing towards a goal? |

---

## Mapping: old order_index → new order_index

Use this if you update by question id or need to audit.

- Old 1 → New 1 | Old 2 → New 2 | Old 3 → New 14 | Old 4 → New 3 | Old 5 → New 4
- Old 6 → New 19 | Old 7 → New 22 | Old 8 → New 5 | Old 9 → New 16 | Old 10 → New 15
- Old 11 → New 6 | Old 12 → New 20 | Old 13 → New 13 | Old 14 → New 7 | Old 15 → New 8
- Old 16 → New 9 | Old 17 → New 23 | Old 18 → New 10 | Old 19 → New 18 | Old 20 → New 24
- Old 21 → New 11 | Old 22 → New 17 | Old 23 → New 12 | Old 24 → New 21

---

## Potential issues

1. **DB has no topic column**  
   Order was inferred from question text. If your real DB has a topic/category column, we could use it for a stricter interleave; otherwise this order is a best-effort from the current list.

2. **Existing rows identified by `question_text`**  
   UPDATEs will use `question_text` to match rows. Any typo or change in wording in the DB will skip that row (or fail if you add a uniqueness check). If you have stable `id`s, updating by `id` is safer after you map id → new order_index once.

3. **Same app, two projects (Centered vs Faith Checkin)**  
   Both use the same `insert_guided_questions.sql`-style list. If they share one Supabase DB, one migration updates both. If they use different DBs, you need to run the same UPDATE in each.

4. **“Today’s” question can change on the day you deploy**  
   The app uses `daysSinceReference % 24` to pick the question. Changing `order_index` changes which question is “today’s” for each day index. Users might see a different question than they saw in the morning after you deploy. You can’t avoid this if you change order; you can only deploy at a quiet time.

5. **Caching / stale data**  
   If the app or a backend caches the ordered list, clear that cache after the migration so everyone gets the new order.

6. **Mock data in code**  
   Centered’s `SupabaseService` mock returns only 5 questions with hardcoded `orderIndex` 1–5. If you use mocks in dev/tests, either add the full 24 with the new order or accept that mock order differs from production.

7. **Notifications**  
   If you schedule notifications with “tomorrow’s question” by computing it client- or server-side, that logic uses the same ordered list. After the migration, new notifications will use the new order; already-scheduled ones might have been built with the old order (minor inconsistency until they fire).

---

Once you approve this order, next step is to add a migration script that updates `guided_questions.order_index` (by `question_text` or by `id`) to these new values, and to run it in the right DB(s). I can draft that migration script when you’re ready.
