-- 01-break-it.sql
--
-- Five failures, in the order you should do them on stage.
-- Run these one at a time. Do not paste the whole file.


-- ---------------------------------------------------------------
-- 1. Austin does not fit
-- ---------------------------------------------------------------
-- 55 characters into a 50 character column. He is not absurdly too
-- long. He is barely too long. You picked 50 because it was there.

INSERT INTO everything_i_remember (who, misc)
VALUES ('Austin, Duke of the Long Dark Where I Do Not Go Anymore',
        'royalty. unrepresentable.');

-- ERROR:  value too long for type character varying(50)
--
-- "He has been erased from the record on a technicality."


-- ---------------------------------------------------------------
-- 2. The dirt ratings are lying to you
-- ---------------------------------------------------------------
-- First, look at them. They are fine. Nothing is wrong.

SELECT id, dirt_rating
FROM everything_i_remember
WHERE dirt_rating IS NOT NULL
ORDER BY id;

-- Now ask whether the number you typed is the number you have.

SELECT 4.1::real = 4.1 AS "is 4.1 equal to 4.1";

--  f
--
-- (Verify this one on your instance. Type resolution sends both sides to
--  double precision, which is what exposes the difference. If it comes back
--  true for any reason, skip straight to the cast below, which cannot fail.)

-- Here is why. This is what is actually in there.

SELECT id, dirt_rating, dirt_rating::float8 AS what_is_actually_stored
FROM everything_i_remember
WHERE dirt_rating IS NOT NULL
ORDER BY id;

--  4.1  ->  4.099999904632568
--  2.2  ->  2.200000047683716
--  4.4  ->  4.400000095367432
--
-- `real` is four bytes. 4.1 is not one of the numbers four bytes can hold,
-- so Postgres stored the closest one it had.
--
-- And it never told you, because since version 12 it prints the shortest
-- number that reads back as the same float. It showed you 4.1 because 4.1
-- round-trips. It was being polite.
--
-- That politeness is the whole problem. You will not notice until you do
-- arithmetic, and by then it is in a report with your name on it.
--
-- "I rated that dirt 4.1. The database has 4.099999904632568.
--  Nobody has ever felt that way about dirt."


-- ---------------------------------------------------------------
-- 3. Renaming a tunnel breaks reality
-- ---------------------------------------------------------------
-- The Long Dark is now The Long Dark Where I Do Not Go Anymore.
-- There is no tunnels table. There is only this string column.

UPDATE everything_i_remember
SET tunnels_involved = replace(tunnels_involved,
                               'The Long Dark',
                               'The Long Dark Where I Do Not Go Anymore');

-- Now look at what you have:

SELECT DISTINCT trim(t) AS tunnel
FROM everything_i_remember,
     unnest(string_to_array(tunnels_involved, ',')) AS t
WHERE tunnels_involved IS NOT NULL
ORDER BY tunnel;

-- 'the long dark' and 'Long Dark' survived untouched. The database
-- now believes in three different tunnels that are one tunnel.
-- Nothing is wrong. Nothing threw an error. It is just false now.


-- ---------------------------------------------------------------
-- 4. A boolean cannot hold a grudge
-- ---------------------------------------------------------------

SELECT who, grudge, grudge_notes
FROM everything_i_remember
WHERE grudge IS TRUE;

-- Point at the screen. In some rows `who` is the worm you are angry
-- at. In others `who` is you, and the target is buried in prose.
-- One row holds two grudges in one boolean.
--
-- Ask the room: is Tommy a worm I am mad at, or a worm who is mad?
-- The table does not know. You wrote it and you do not know either.


-- ---------------------------------------------------------------
-- Before 5: forget it (you can't, and that's the point)
-- ---------------------------------------------------------------
-- Paste these one at a time. NEVER skip BEGIN: psql autocommits, so
-- without it the DROP is permanent and you are re-running 00 on stage.

BEGIN;

DROP TABLE everything_i_remember;

\dt

-- Did not find any tables. Right back where I started.
--
-- ...No. I need it. It's the only record I have of what not to do.

ROLLBACK;

\dt

-- Back. In Postgres, even DDL is transactional: dropping a table is
-- something you can take back, as long as you haven't committed. Most
-- databases commit DDL the moment you run it. The worm can forget
-- something, and take it back.


-- ---------------------------------------------------------------
-- 5. The question you cannot ask
-- ---------------------------------------------------------------
-- "Who am I currently holding a grudge against, how bad is it,
--  when did it start, and is it over?"
--
-- Try it. Out loud. There is no query.
--
-- There is no column for who the grudge is against. There is no
-- column for severity. `timestamp` is when you wrote it down, not
-- when it started. And there is nowhere at all to record that
-- something ended.
--
-- This is the hinge. Everything before this was funny. This one is
-- just true: you cannot ask your own data the only question you
-- actually care about.
--
-- "Okay. Let's do this on purpose."
