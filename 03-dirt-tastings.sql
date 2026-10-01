-- 03-dirt-tastings.sql
--
-- A worm eats dirt in many tunnels.
-- A tunnel is eaten in by many worms.
-- Neither table can hold that.

DROP TABLE IF EXISTS dirt_tastings;
DROP TYPE IF EXISTS dirt_texture;


CREATE TYPE dirt_texture AS ENUM (
  'loamy',
  'gritty',
  'suspiciously_damp',
  'concerning'
);

-- An enum is a short, fixed ladder of allowed values. Cheap, readable,
-- and annoying to change later — which is the trade. If the list will
-- grow every month, use a lookup table instead.


CREATE TABLE dirt_tastings (
  id        bigint GENERATED ALWAYS
            AS IDENTITY PRIMARY KEY,
  worm_id   bigint NOT NULL REFERENCES worms(id),
  tunnel_id bigint NOT NULL REFERENCES tunnels(id),
  tasted_at timestamptz NOT NULL DEFAULT now(),
  rating    numeric(3,1),
  texture   dirt_texture,
  notes     text,

  CHECK (rating BETWEEN 0 AND 5)
);

-- Two foreign keys, to two different tables. That is the whole trick.
--
-- And then notice what happened: the relationship turned out to have its
-- own facts. When you ate it. What you thought. How damp it was.
--
-- The interesting thing was never the worm and it was never the tunnel.
-- It was the opinion. The join table is the most interesting table here.
--
-- `rating numeric(3,1)` — deliberately, after what real did to us.


INSERT INTO dirt_tastings (worm_id, tunnel_id, tasted_at, rating, texture, notes)
SELECT w.id, t.id, v.tasted_at, v.rating, v.texture, v.notes
FROM (VALUES
    ('me',       'Near The Old Root', '2026-02-01 06:30-08'::timestamptz, 4.1, 'loamy'::dirt_texture,
     'excellent. the standard by which all dirt is judged.'),
    ('me',       'By The Rock',       '2026-02-01 18:45-08'::timestamptz, 2.2, 'gritty',
     'would not recommend. why is it warm.'),
    ('me',       'The Long Dark',     '2026-02-03 22:10-08'::timestamptz, 4.2, 'suspiciously_damp',
     'damp but in a good way'),
    ('me',       'The Long Dark',     '2026-02-08 23:55-08'::timestamptz, 3.7, 'suspiciously_damp',
     'same place as before. I can tell now. one row, one tunnel.'),
    ('me',       'Mudroom',           '2026-02-14 12:00-08'::timestamptz, 3.9, 'concerning',
     'ate it anyway'),
    ('me',       'The Long Dark',     '2026-03-02 03:00-08'::timestamptz, 4.4, 'loamy',
     'best yet. wrote this at 3am. now verifiable.'),
    ('Stephen',  'Mudroom',           '2026-01-09 08:00-08'::timestamptz, 4.0, 'loamy',
     'he dug it, he rates it highly, draw your own conclusions'),
    ('Tommy',    'The Long Dark',     '2026-01-04 09:40-08'::timestamptz, 1.0, 'concerning',
     NULL),
    ('Chelsea',  'The Long Dark',     '2026-02-20 14:00-08'::timestamptz, 4.6, 'loamy',
     NULL),
    ('Mortimer', 'By The Rock',       '2026-01-31 09:15-08'::timestamptz, 4.8, 'gritty',
     'he dug it. same conclusion.'),
    ('Greg?',    'Mudroom',           '2026-01-11 16:02-08'::timestamptz, 3.0, NULL,
     'did not elaborate')
) AS v(worm_name, tunnel_name, tasted_at, rating, texture, notes)
JOIN worms   w ON w.name = v.worm_name
JOIN tunnels t ON t.name = v.tunnel_name;


-- ---------------------------------------------------------------
-- The dirt ratings are no longer lying to you
-- ---------------------------------------------------------------
-- The exact question from failure 2, asked of numeric instead of real.

SELECT rating, rating = 4.1 AS "is 4.1 equal to 4.1"
FROM dirt_tastings
WHERE rating = 4.1;

--  4.1 | t
--
-- numeric stored the number you typed. That is the whole difference.
