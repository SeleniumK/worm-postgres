-- 04-grudges.sql
--
-- This is the same thing we just did, with one change.
--
-- Say that out loud before you type anything.

DROP TABLE IF EXISTS grudges;
DROP TYPE IF EXISTS grudge_severity;


-- ---------------------------------------------------------------
-- Warm-up: Stephen
-- ---------------------------------------------------------------
-- One column. A worm, pointing at a worm.

ALTER TABLE worms
    ADD COLUMN IF NOT EXISTS introduced_by_worm_id bigint REFERENCES worms(id);

UPDATE worms
SET introduced_by_worm_id = (SELECT id FROM worms WHERE name = 'Stephen')
WHERE name <> 'Stephen';

-- Everyone was introduced by Stephen. Stephen knows everyone.
-- Nobody knows who introduced Stephen — and that is what the nullable
-- column is for. The recursion has to stop somewhere.
--
-- Stephen is the only NULL in the result. Point at it.

SELECT w.name, i.name AS introduced_by
FROM worms w
LEFT JOIN worms i ON i.id = w.introduced_by_worm_id
ORDER BY w.id;

-- The one on the slide. Who introduced Stephen? Nobody knows.
SELECT name FROM worms
WHERE introduced_by_worm_id IS NULL;
--  Stephen


-- ---------------------------------------------------------------
-- grudges
-- ---------------------------------------------------------------

CREATE TYPE grudge_severity AS ENUM (
    'mild',
    'simmering',
    'generational'
);

CREATE TABLE grudges (
  wronged_worm_id   bigint NOT NULL
                    REFERENCES worms(id),
  offending_worm_id bigint NOT NULL
                    REFERENCES worms(id),
  severity          grudge_severity NOT NULL,
  reason            text NOT NULL,
  formed_at         timestamptz NOT NULL DEFAULT now(),
  resolved_at       timestamptz,

  PRIMARY KEY (wronged_worm_id, offending_worm_id),
  CHECK (wronged_worm_id <> offending_worm_id)
);

-- Build this column by column on stage. Each one is one idea.
--
--   two FKs, same table    the grudge knows its direction now. that is the
--                          thing the boolean could never do.
--
--   reason NOT NULL        you cannot hold a grudge you cannot articulate.
--                          that is a policy, enforced by the database.
--
--   severity               mild, simmering, generational. worms do not live
--                          that long. neither does a missed conference.
--
--   resolved_at nullable   NULL means it is still going.
--
--   CHECK (<>)             you cannot hold a grudge against yourself.
--
--   composite PK           one grudge per worm per worm. they wrong you
--                          twice, it is the same grudge, escalated.


INSERT INTO grudges (wronged_worm_id, offending_worm_id, severity, reason, formed_at, resolved_at)
SELECT a.id, b.id, v.severity, v.reason, v.formed_at, v.resolved_at
FROM (VALUES
    ('me',      'Tommy',    'generational'::grudge_severity, 'did not come to NYC',
     '2026-01-04 09:40-08'::timestamptz, NULL::timestamptz),
    ('Tommy',   'me',       'simmering',    'unclear. he has not said. he will not say.',
     '2026-01-04 09:41-08'::timestamptz, NULL),
    ('me',      'Chelsea',  'generational', 'inherited. the soil remembers. I do not.',
     '2025-08-15 00:00-07'::timestamptz, NULL),
    ('Chelsea', 'Stephen',  'mild',         'brought something back from the Long Dark',
     '2026-02-20 14:00-08'::timestamptz, '2026-02-21 09:00-08'::timestamptz),
    ('Mortimer','Greg?',    'mild',         'rated the Mudroom a 3 without elaborating',
     '2026-01-11 16:30-08'::timestamptz, NULL)
) AS v(wronged, offending, severity, reason, formed_at, resolved_at)
JOIN worms a ON a.name = v.wronged
JOIN worms b ON b.name = v.offending;


-- The three constraint demos live in 04a-break-the-constraints.sql, so this
-- file is pure setup and `\i` runs clean.

SELECT wronged.name AS wronged, offending.name AS offending, g.severity, g.reason
FROM grudges g
JOIN worms wronged   ON wronged.id   = g.wronged_worm_id
JOIN worms offending ON offending.id = g.offending_worm_id
ORDER BY g.formed_at;
