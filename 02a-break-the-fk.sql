-- 02a-break-the-fk.sql
--
-- Paste this one, alone, after \i 02-worms-and-tunnels.sql.
-- Do not \i this file — the whole point is one statement, one beat.
--
-- There is no worm 999. There never was.

INSERT INTO tunnels (name, dug_by_worm_id, depth_cm)
VALUES ('A Tunnel Dug By Nobody', 999, 10.0);

-- ERROR:  insert or update on table "tunnels" violates foreign key constraint
--         "tunnels_dug_by_worm_id_fkey"
-- DETAIL: Key (dug_by_worm_id)=(999) is not present in table "worms".
--
-- WAIT for the error to render. Then:
--
--   "The database has more integrity than I do."
--
-- A foreign key is not bookkeeping. It is the database refusing to record
-- something that cannot be true.
