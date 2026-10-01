-- 02-worms-and-tunnels.sql
--
-- Okay. Let's do this on purpose.
--
-- Two real tables. Things that exist once, in one place, with one spelling.

DROP TABLE IF EXISTS tunnels CASCADE;
DROP TABLE IF EXISTS worms CASCADE;


-- ---------------------------------------------------------------
-- worms
-- ---------------------------------------------------------------

CREATE TABLE worms (
  id        bigint GENERATED ALWAYS
            AS IDENTITY PRIMARY KEY,
  name      text    NOT NULL,
  length_mm numeric(5,1),
  is_me     boolean NOT NULL DEFAULT false,

  CHECK (length_mm > 0)
);

-- `text`, not varchar(50). Austin is restored. The Duke lives.
--
-- `bigint GENERATED ALWAYS AS IDENTITY` has superseded `serial`.
-- If you have seen `serial` in older tutorials, use this instead.
--
-- `length_mm numeric(5,1)` because you will average this someday.
--
-- The CHECK says a worm cannot have a negative length. You did not need a
-- comment to say that. The database says it.

INSERT INTO worms (name, length_mm, is_me) VALUES
    ('me',                                                     88.0, true),
    ('Stephen',                                                92.5, false),
    ('Tommy',                                                  81.0, false),
    ('Chelsea',                                                95.0, false),
    ('Greg?',                                                  NULL, false),
    ('Mortimer',                                              104.5, false),
    ('Austin, Duke of the Long Dark Where I Do Not Go Anymore', 79.0, false);


-- ---------------------------------------------------------------
-- tunnels
-- ---------------------------------------------------------------

CREATE TABLE tunnels (
  id             bigint GENERATED ALWAYS
                 AS IDENTITY PRIMARY KEY,
  name           text   NOT NULL UNIQUE,
  dug_by_worm_id bigint NOT NULL
                 REFERENCES worms(id),
  depth_cm       numeric(5,1),
  dug_at         timestamptz
);

-- `name text NOT NULL UNIQUE` is the direct fix for the rename disaster.
-- There is now exactly one row that means The Long Dark. Rename it once and
-- every worm, every tasting, every memory follows automatically, because
-- nothing else stores the name at all.
--
-- `dug_by_worm_id NOT NULL REFERENCES worms(id)` is a one-to-many. One worm
-- digs many tunnels. Each tunnel was dug by exactly one worm.

INSERT INTO tunnels (name, dug_by_worm_id, depth_cm, dug_at)
SELECT v.name, w.id, v.depth_cm, v.dug_at
FROM (VALUES
    ('The Long Dark',      'Austin, Duke of the Long Dark Where I Do Not Go Anymore', 140.0, '2025-11-02 04:00-08'::timestamptz),
    ('Mudroom',            'Stephen',                                                  35.5, '2026-01-08 11:20-08'::timestamptz),
    ('Near The Old Root',  'me',                                                       62.0, '2026-01-29 06:00-08'::timestamptz),
    ('The Escape Hatch',   'me',                                                       15.0, '2026-03-02 03:10-08'::timestamptz),
    ('By The Rock',        'Mortimer',                                                 20.0, '2026-01-30 17:45-08'::timestamptz),
    ('that one place',     'Greg?',                                                    NULL, NULL)
) AS v(name, digger, depth_cm, dug_at)
JOIN worms w ON w.name = v.digger;


-- The foreign key demo lives in 02a-break-the-fk.sql, so this file is pure
-- setup and `\i` runs clean.

SELECT t.name AS tunnel, w.name AS dug_by, t.depth_cm
FROM tunnels t
JOIN worms w ON w.id = t.dug_by_worm_id
ORDER BY t.name;
