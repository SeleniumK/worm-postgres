-- 00-the-3am-table.sql
--
-- You are a worm. You woke up with no memory and a mounting sense of urgency.
-- You made a table. It seemed fine at the time.
--
-- Run this, then run 01-break-it.sql.

DROP TABLE IF EXISTS everything_i_remember;

CREATE TABLE everything_i_remember (
  id               serial PRIMARY KEY,
  who              varchar(50), -- names run long
  tunnels_involved text,        -- 'Long Dark, Mudroom'
  dirt_rating      real,        -- a float, to average
  "timestamp"      timestamp,   -- no zone. quoted.
  grudge           boolean,     -- can't hold a grudge
  grudge_notes     text,        -- so, a second column
  misc             text         -- the junk drawer
);

-- The deepest problem with this table is not any single column.
-- It is that no two rows mean the same thing. Some rows are worms
-- you met. Some are dirt you ate. Some are grievances. The table
-- has no grain. Ask it a question and it does not know which
-- question you are asking.

INSERT INTO everything_i_remember
    (who, tunnels_involved, dirt_rating, "timestamp", grudge, grudge_notes, misc)
VALUES
    -- worms you have met, allegedly
    ('Stephen',  'The Long Dark',                 NULL, '2026-01-04 09:12', false, NULL,
     'introduced me to everyone. no idea who introduced him.'),
    ('Tommy',    'The Long Dark, Mudroom',        NULL, '2026-01-04 09:40', true,  'he knows what he did',
     NULL),
    ('Chelsea',  'the long dark',                 NULL, NULL,               true,  'generational. do not ask.',
     'Stephen introduced us'),
    ('Greg?',    'Mudroom',                       NULL, '2026-01-11 16:02', false, NULL,
     'not sure that is his name. not sure he is a worm.'),
    ('Mortimer', 'that one place',                NULL, '2026-02-19 08:00', false, NULL,
     'Stephen introduced us'),

    -- dirt you have eaten and had feelings about
    ('me',       'Near The Old Root',              4.1, '2026-02-01 06:30', NULL,  NULL,
     'loamy. excellent. the standard by which all dirt is judged.'),
    ('me',       'By The Rock',                    2.2, '2026-02-01 18:45', NULL,  NULL,
     'gritty. would not recommend. why is it warm.'),
    ('me',       'The Long Dark',                  4.2, '2026-02-03 22:10', NULL,  NULL,
     'suspiciously damp but in a good way'),
    ('me',       'Long Dark',                      3.7, '2026-02-08 23:55', NULL,  NULL,
     'same place as above? unclear. I was tired.'),
    ('me',       'Mudroom',                        3.9, '2026-02-14 12:00', NULL,  NULL,
     'concerning. ate it anyway.'),
    ('me',       'the long dark',                  4.4, '2026-03-02 03:00', NULL,  NULL,
     'best yet. wrote this at 3am. cannot verify.'),

    -- grievances, filed inconsistently
    ('me',       NULL,                            NULL, '2026-03-02 03:04', true,  'Tommy AND Chelsea. separate incidents.',
     'the boolean is doing a lot of work here'),
    ('Tommy',    NULL,                            NULL, NULL,               true,  'did not come to NYC',
     NULL),
    ('me',       'The Long Dark',                 NULL, '2026-03-05 07:30', false, NULL,
     'I think I used to have a job');

-- A narrow look at the mess. The full width does not fit a projector.
SELECT id, who, tunnels_involved, dirt_rating, grudge
FROM everything_i_remember
ORDER BY id;
