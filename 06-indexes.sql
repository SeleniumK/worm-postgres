-- 06-indexes.sql
--
-- RUN THIS LAST. It adds 200,000 worms to your database.
-- To get back to the clean schema: docker compose down -v && docker compose up -d
--
-- Five rows will never produce a seq scan you can point at. The planner
-- will just read the whole table because the whole table is nothing.
-- So first, a great many more worms than you have ever met.


-- ---------------------------------------------------------------
-- More worms than anyone needs
-- ---------------------------------------------------------------

INSERT INTO worms (name)
SELECT 'worm_' || g FROM generate_series(1, 200000) AS g;

INSERT INTO grudges (wronged_worm_id, offending_worm_id, severity, reason)
SELECT a.id, b.id, 'mild', 'unspecified grievance'
FROM worms a
JOIN worms b ON b.id = a.id + 1
WHERE a.name LIKE 'worm!_%' ESCAPE '!'
  AND b.name LIKE 'worm!_%' ESCAPE '!';

ANALYZE worms;
ANALYZE grudges;

-- ANALYZE tells the planner what is actually in the table. Without it the
-- planner is guessing, and a guessing planner makes bad choices. This runs
-- automatically in the background in real life; we are just impatient.


-- ---------------------------------------------------------------
-- The index you already have and did not ask for
-- ---------------------------------------------------------------
-- The composite primary key on (wronged_worm_id, offending_worm_id)
-- created an index for free. Watch:

EXPLAIN ANALYZE
SELECT * FROM grudges WHERE wronged_worm_id = 100000;

-- Index scan. Sub-millisecond. You never typed CREATE INDEX.
-- Most people's first index already exists and they do not know it.


-- ---------------------------------------------------------------
-- The index you do not have
-- ---------------------------------------------------------------
-- Same table, same shape of question, other direction:

EXPLAIN ANALYZE
SELECT * FROM grudges WHERE offending_worm_id = 100000;

-- Seq scan. Every row. Point at the number.
--
-- Why? A composite index is sorted by its first column. Asking about
-- the second column alone is like looking someone up in the phone book
-- by their first name. The book is sorted, just not for this question.


-- ---------------------------------------------------------------
-- Fix it
-- ---------------------------------------------------------------

CREATE INDEX grudges_offending_worm_id_idx ON grudges (offending_worm_id);

EXPLAIN ANALYZE
SELECT * FROM grudges WHERE offending_worm_id = 100000;

-- Index scan. Point at the new number. Say the difference out loud.


-- ---------------------------------------------------------------
-- The honest part
-- ---------------------------------------------------------------
-- An index is a second copy of your data, sorted, that Postgres maintains
-- for you. That is why reads get fast and writes get slower. That is the
-- whole trade.
--
-- Indexes cost you on every INSERT, every UPDATE, and every byte of disk.
-- Adding them speculatively is how you end up with a slow database that
-- has beautiful query plans.
--
-- b-tree is the default and is almost always the right answer. The others
-- exist and are well documented:
-- https://www.postgresql.org/docs/current/indexes-types.html
--
-- Making it faster is now, formally, someone else's problem.
