-- 04a-break-the-constraints.sql
--
-- Paste these one at a time, after \i 04-grudges.sql.
-- Do not \i this file. Each one needs its own beat.


-- ---------------------------------------------------------------
-- 1. You cannot hold a grudge against yourself
-- ---------------------------------------------------------------

INSERT INTO grudges (wronged_worm_id, offending_worm_id, severity, reason)
SELECT id, id, 'generational', 'I should have known'
FROM worms WHERE name = 'me';

-- ERROR:  new row for relation "grudges" violates check constraint
--
-- WAIT for the error. Then: "The worm tries anyway."


-- ---------------------------------------------------------------
-- 2. You cannot hold a grudge you cannot articulate
-- ---------------------------------------------------------------

INSERT INTO grudges (wronged_worm_id, offending_worm_id, severity, reason)
SELECT a.id, b.id, 'simmering', NULL
FROM worms a, worms b WHERE a.name = 'me' AND b.name = 'Mortimer';

-- ERROR:  null value in column "reason" of relation "grudges" violates
--         not-null constraint


-- ---------------------------------------------------------------
-- 3. One grudge per pair
-- ---------------------------------------------------------------

INSERT INTO grudges (wronged_worm_id, offending_worm_id, severity, reason)
SELECT a.id, b.id, 'generational', 'still did not come to NYC'
FROM worms a, worms b WHERE a.name = 'me' AND b.name = 'Tommy';

-- ERROR:  duplicate key value violates unique constraint "grudges_pkey"
--
-- If they wrong you again you do not file a second grudge. You escalate the
-- one you have:
--
-- UPDATE grudges SET severity = 'generational'
-- WHERE wronged_worm_id   = (SELECT id FROM worms WHERE name = 'me')
--   AND offending_worm_id = (SELECT id FROM worms WHERE name = 'Tommy');
