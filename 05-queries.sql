-- 05-queries.sql
--
-- Four questions. Each one was impossible or miserable against the 3am table.
-- Run them one at a time. Say which one it was, each time.


-- ---------------------------------------------------------------
-- 1. Who do I owe an apology to?
-- ---------------------------------------------------------------
-- Against the 3am table: unanswerable. There was no column for the target.

SELECT w.name          AS wronged_worm,
       g.severity,
       g.reason,
       g.formed_at::date AS since
FROM grudges g
JOIN worms w ON w.id = g.wronged_worm_id
WHERE g.offending_worm_id = (SELECT id FROM worms WHERE is_me)
  AND g.resolved_at IS NULL
ORDER BY g.formed_at;

-- `resolved_at IS NULL` means it is still going. That is the whole filter.


-- ---------------------------------------------------------------
-- 2. Which tunnel has the best dirt?
-- ---------------------------------------------------------------
-- Against the 3am table: the tunnel name was a comma-separated string in
-- three different spellings, and the rating was a float.

SELECT t.name                   AS tunnel,
       count(*)                 AS tastings,
       round(avg(d.rating), 2)  AS avg_rating
FROM dirt_tastings d
JOIN tunnels t ON t.id = d.tunnel_id
GROUP BY t.name
ORDER BY avg_rating DESC;

--  Near The Old Root  1  4.10
--  Mudroom            3  3.63
--  The Long Dark      5  3.58
--  By The Rock        2  3.50
--
-- Read the top and bottom rows out loud. "The dirt near the old root is
-- better than the dirt by the rock." You said that at minute one, on
-- nothing but a feeling. The data agrees. That is the whole talk in one
-- result set, and it is worth a beat.


-- ---------------------------------------------------------------
-- 3. Which tunnels have I dug but never eaten in?
-- ---------------------------------------------------------------
-- Against the 3am table: there was no concept of a tunnel at all.
--
-- This is a LEFT JOIN, which means "give me the rows on the left even
-- when there is nothing on the right." Then WHERE ... IS NULL keeps only
-- the ones where there was nothing on the right.
--
-- The absence is the answer. That is the part worth saying out loud.

SELECT t.name AS tunnel_i_dug_and_never_ate_in
FROM tunnels t
LEFT JOIN dirt_tastings d
       ON d.tunnel_id = t.id
      AND d.worm_id   = (SELECT id FROM worms WHERE is_me)
WHERE t.dug_by_worm_id = (SELECT id FROM worms WHERE is_me)
  AND d.id IS NULL;


-- ---------------------------------------------------------------
-- 4. Grudges I hold, versus grudges held against me
-- ---------------------------------------------------------------
-- The same table, joined twice. This is the flex and the callback.
--
-- Tommy appears on both sides. reason: 'did not come to NYC'. resolved_at: NULL.

SELECT 'I hold this against them' AS direction,
       them.name                  AS worm,
       g.severity,
       g.reason,
       g.formed_at::date          AS since,
       g.resolved_at
FROM grudges g
JOIN worms them ON them.id = g.offending_worm_id
WHERE g.wronged_worm_id = (SELECT id FROM worms WHERE is_me)

UNION ALL

SELECT 'they hold this against me',
       them.name,
       g.severity,
       g.reason,
       g.formed_at::date,
       g.resolved_at
FROM grudges g
JOIN worms them ON them.id = g.wronged_worm_id
WHERE g.offending_worm_id = (SELECT id FROM worms WHERE is_me)

ORDER BY worm, direction;

-- Two questions of the same table, stacked. That is all UNION ALL does:
-- run both, put one result underneath the other.
--
-- The first one asks the table about `wronged_worm_id`. The second asks it
-- about `offending_worm_id`. Same rows, read from two directions.
--
-- Tommy appears twice, adjacent. Once in each direction. Neither resolved.

-- The line to land on:
--
-- At minute one this was a feeling. Now it is a row, with a direction, a
-- severity, a start date, and a very conspicuous NULL where the ending goes.
