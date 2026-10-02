# The walkthrough

*Would you still love me if I was a worm (who needed to learn Postgres)?*
Selena Flannery · Postgres Summit US 2026

Hi, I'm Selena. For roughly the last decade I've been running Postgres fleets,
debugging problems in distributed data land, and bridging the gap between the
folks running the k8s clusters and the data engineers and DBAs. Most mistakes in
this walkthrough are ones I have personally made. Or something similar. Several
of them more than once.

This is the talk, written down. If you weren't in the room (or you were, and
want to run it yourself), it walks through the whole thing. We build a bad
table, break it five ways, rebuild it properly as four tables with real types
and real constraints, and then ask it the questions the bad table couldn't
answer.

Every step runs a numbered file from this repo, in order. Where it helps, I've
put the output you should see underneath, in psql's default format. Your column
widths may be a little different.

You don't need to know any Postgres to follow along. You do need to be a worm.

---

## 0 · You are a worm

You wake up as a worm. No memory, no notes, no idea what you used to do. You
have a body that is mostly tube, and you are in the ground.

But you know three things:

> You live underground.\
> The dirt near the old root is better than the dirt by the rock.\
> Tommy knows what he did.

That last one is the only thing you're actually sure of. You don't know what he
did. You don't know when. You definitely couldn't explain it to another worm if
they asked. But you're certain, and you intend to keep acting on it.

That's data. Certainty with no structure. Facts you can't defend. Questions you
can't answer about things you already know.

The whole job of a data model is turning "Tommy knows what he did" into
something you can query. The goal here is definitely not to come out an expert
on anything, but we will come out with a schema we can use, and possibly even
defend. By the end, we should be able to ask the database who wronged us, how
badly, when it started, and whether it's over.

---

## 1 · Getting Postgres running

We're going to hand-wave getting Postgres running. There are better guides out
there for that; for now, we just need a database.

You need Docker and the `psql` command-line client. If you already have
Postgres installed, you already have `psql`. If not:

- **macOS:** `brew install libpq && brew link --force libpq`
- **Debian or Ubuntu:** `sudo apt install postgresql-client`

Docker is great for this kind of quick experimentation. One command, one
container, and it throws away cleanly. When you're done, delete it and it's
like it never happened. Which, for a worm, is relatable.

From this folder:

```
docker compose up -d
psql postgresql://worm:worm@localhost:5432/worm
```

That connection string is the only thing here worth memorizing: user,
password, host, port, database, in that order. Once you can read that, every
Postgres tutorial on the internet gets a lot more useful.

> **If you already run Postgres on your machine,** it's probably using port
> 5432 too, and psql will quietly connect to that instead of the container. You'll
> get an error ending in `role "worm" does not exist`. (Ask me how I know.)
> Stop your local Postgres, or change the port mapping in `docker-compose.yml`
> to `"5433:5432"` and connect to port 5433.

Inside psql, you only need four commands for this whole walkthrough:

```
\dt          list tables
\d worms     describe a table
\i file.sql  run a file
\q           quit
```

`\d` is describe: when you want to know what a table actually looks like, this
is how you ask, and you'll ask constantly for the rest of time. `\i` runs a
file. `\q` gets you out.

Try the first one:

```
worm=# \dt
Did not find any tables.
```

(Older versions of psql say "relations" instead of "tables".) No tables. This
is my brain, currently. We have a database, and it is completely empty, which
is convenient, because so are we.

---

## 2 · Start with sentences, not `CREATE TABLE`

Before I type anything, I'm going to say what's true. In sentences. Like a
person.

> I am a worm. I have met other worms.\
> I dig tunnels. Other worms dig tunnels.\
> I eat dirt, and I have opinions about it.\
> I am holding grudges. Some of them are very old.

Nouns (worm, tunnel, dirt, grudge) become tables. Verbs (met, dig, eat,
holding) become relationships. And adjectives become columns, so let's find
the adjectives.

There's one. "Old." Four tables, four relationships, one column. This seems a
little lopsided; seems like we don't know quite enough yet. So let me say more:

> The dirt near the old root is better than the dirt by the rock.

"Better": that's a rating. "Near the old root" and "by the rock": two named
places. One more true sentence and I have a rating, a location, and a reason to
compare them.

You don't get the model in one pass. You get it by saying more true things
until the columns start to show themselves.

And importantly, I haven't made a single Postgres decision yet. This part is
the same in every database, and it's the part everybody is tempted to skip.

So that's where we start. **Nouns are tables. Verbs are relationships.** That's
the method. Most everything after this is syntax.

So obviously the first thing you do is ignore all of that and make one big
table at 3am.

---

## 3 · The 3am table

```
\i 00-the-3am-table.sql
```

This is what worm me made. It seemed fine at the time.

```sql
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
```

Take a minute and read it before moving on. Finding the problems yourself is
more fun than having me point at them.

(The first time you run the file, you'll see `NOTICE: table
"everything_i_remember" does not exist, skipping`. That's harmless: the file
starts with `DROP TABLE IF EXISTS` so you can rerun it. Then it inserts 14 rows
and shows you a few columns.)

Before we get into the columns: the worst thing here isn't any one of them.
It's that no two rows mean the same thing. Some rows are worms I've met. Some
are dirt I ate. Some are grievances. This table has no *grain*. Ask it a
question and it doesn't know which question you're asking.

Here it is, as Postgres sees it:

```
worm=# \d everything_i_remember
                     Table "public.everything_i_remember"
      Column      |            Type             | Nullable |                      Default
------------------+-----------------------------+----------+---------------------------------------------------
 id               | integer                     | not null | nextval('everything_i_remember_id_seq'::regclass)
 who              | character varying(50)       |          |
 tunnels_involved | text                        |          |
 dirt_rating      | real                        |          |
 timestamp        | timestamp without time zone |          |
 grudge           | boolean                     |          |
 grudge_notes     | text                        |          |
 misc             | text                        |          |
Indexes:
    "everything_i_remember_pkey" PRIMARY KEY, btree (id)
```

(I've trimmed the Collation column; it's empty for every row.)

Alright, now let's get into those columns, and see where things get even more
broken.

---

## 4 · Break it

Open `01-break-it.sql` and paste its statements into psql **one at a time**.
Don't `\i` this one: it contains an `UPDATE`, and each failure is worth seeing
on its own.

### One: Austin does not fit

```sql
INSERT INTO everything_i_remember (who, misc)
VALUES ('Austin, Duke of the Long Dark Where I Do Not Go Anymore',
        'royalty. unrepresentable.');
```

```
ERROR:  value too long for type character varying(50)
```

That's Austin, Duke of the Long Dark Where I Do Not Go Anymore. He's fifty-five
characters. The column is fifty. I did not pick fifty for any reason. I picked
fifty because it was there. Austin has been erased from the record on a
technicality.

### Two: the dirt ratings are lying to you

```sql
SELECT id, dirt_rating
FROM everything_i_remember
WHERE dirt_rating IS NOT NULL
ORDER BY id;
```

These are my dirt ratings: 4.1, 2.2, 4.2, 3.7, 3.9, 4.4. They look fine.
Nothing is wrong. So let's ask whether the number I typed is the number I have:

```sql
SELECT 4.1::real = 4.1 AS "is 4.1 equal to 4.1";
```

```
 is 4.1 equal to 4.1
---------------------
 f
```

Is 4.1 equal to 4.1? No. Here's what's actually in there:

```sql
SELECT id, dirt_rating, dirt_rating::float8 AS what_is_actually_stored
FROM everything_i_remember
WHERE dirt_rating IS NOT NULL
ORDER BY id;
```

```
 id | dirt_rating | what_is_actually_stored
----+-------------+-------------------------
  6 |         4.1 |       4.099999904632568
  7 |         2.2 |       2.200000047683716
  8 |         4.2 |       4.199999809265137
  9 |         3.7 |       3.700000047683716
 10 |         3.9 |      3.9000000953674316
 11 |         4.4 |       4.400000095367432
```

`real` is four bytes. 4.1 is not a number four bytes can hold, so Postgres
stored the closest one it had. And it never told me: it prints the shortest
number that reads back as the same value (that's been the behavior since
Postgres 12), so it showed me 4.1. It was being polite. That politeness is the
whole problem. You won't notice until you do math, and by then it's in a
report with your name on it.

I rated that dirt 4.1. The database has 4.099999904632568. Nobody has ever felt
that way about dirt.

### Three: renaming a tunnel breaks reality

The Long Dark is now called The Long Dark Where I Do Not Go Anymore. There's no
tunnels table, just a string column, so the rename is a find-and-replace:

```sql
UPDATE everything_i_remember
SET tunnels_involved = replace(tunnels_involved,
                               'The Long Dark',
                               'The Long Dark Where I Do Not Go Anymore');
```

```
UPDATE 14
```

Now let's see what tunnels I know about:

```sql
SELECT DISTINCT trim(t) AS tunnel
FROM everything_i_remember,
     unnest(string_to_array(tunnels_involved, ',')) AS t
WHERE tunnels_involved IS NOT NULL
ORDER BY tunnel;
```

```
                 tunnel
-----------------------------------------
 By The Rock
 Long Dark
 Mudroom
 Near The Old Root
 that one place
 the long dark
 The Long Dark Where I Do Not Go Anymore
```

Look what I have. "the long dark", lowercase, survived. "Long Dark", no
article, survived. The database now believes in three tunnels that are one
tunnel. Nothing errored. Nothing crashed. It's just false now.

Also: it took four functions just to ask my own table which tunnels I know
about. `string_to_array` splits the comma-separated string, `unnest` turns the
array into rows, `trim` cleans up the space after each comma, and `DISTINCT`
collapses the repeats. In a real schema, that whole thing is
`SELECT name FROM tunnels`.

### Four: a boolean cannot hold a grudge

```sql
SELECT who, grudge, grudge_notes
FROM everything_i_remember
WHERE grudge IS TRUE;
```

```
   who   | grudge |              grudge_notes
---------+--------+----------------------------------------
 Tommy   | t      | he knows what he did
 Chelsea | t      | generational. do not ask.
 me      | t      | Tommy AND Chelsea. separate incidents.
 Tommy   | t      | did not come to NYC
```

In some rows, `who` is the worm I'm angry at. In others, `who` is me, and the
target is buried in prose. There's a row where the boolean is holding two
grudges at once. Is Tommy a worm I'm mad at, or a worm who's mad? The table
doesn't know. I wrote it, and I don't know either.

A boolean cannot hold a grudge. So I added a second column, `grudge_notes`.
Grudges in prose. Also wrong.

### Forget it (you can't, and that's the point)

At this point I'm tempted to just forget this table exists. Paste these one at
a time:

```
BEGIN;
DROP TABLE everything_i_remember;
\dt
```

```
Did not find any tables.
```

Right back where I started. …Wait. No. I need it. It's the only record I have
of what not to do.

```
ROLLBACK;
\dt
```

```
               List of tables
 Schema |         Name          | Type  | Owner
--------+-----------------------+-------+-------
 public | everything_i_remember | table | worm
```

Back. In Postgres, even dropping a table is something you can take back, as
long as you use the magical thing called a transaction and haven't committed.
Not all databases let you do this. Postgres is friendly. The worm can forget
something, and take it back.

**Don't skip the `BEGIN`, though.** psql commits each statement on its own
unless you open a transaction, so without it the `DROP` is permanent. If that
happens, `\i 00-the-3am-table.sql` and the worm remembers.

### Five: the question you cannot ask

So I kept the table. Let me ask it the big question I actually care about:

> Who am I currently holding a grudge against, how bad is it, when did it
> start, and is it over?

What on earth would that query look like? There's really no query. There's no
column for who a grudge is against. No column for how bad. The timestamp is
when I wrote it down, not when it started. And there is nowhere (anywhere) to
record that something ended. Oops.

Okay. Let's do this on purpose.

---

## 5 · Types: the diagnosis

On purpose starts with one table. Every row is something you just watched go
wrong.

| Use | Instead of | Because |
|---|---|---|
| `text` | `varchar(n)` | Austin |
| `numeric` | `real`, `float8` | 4.1 was never 4.1 |
| `timestamptz` | `timestamp` | no reference point |
| a grudges table | `boolean` | a grudge has a direction |
| `bigint` identity | `int`, `serial` | more worms than you think |
| enum | free text | texture, severity |
| `jsonb` | misc text | the shape is unknown |

Everything here is written with Postgres in mind. Some of it doesn't transfer:
in other databases, `varchar` length does matter. Here (for this specific use
case) it doesn't.

- **`text`, for every string.** `varchar` isn't slower than `text`: same
  storage, same performance, the docs say so. But we picked a length
  arbitrarily. We picked fifty because it was there, and Austin doesn't care.
  (If a length limit is a real rule, `varchar(n)` or a `CHECK` is totally fine.
  Just don't pick the number because it was there.)
- **`numeric`, for anything you'll compare or add up.** It stores exactly the
  number you typed, to as many decimal places as you tell it to keep
  (`numeric(3,1)` keeps one). Floats store the closest number they can hold,
  then print it back so politely you don't find out until you compare or add
  things up. Fine when close enough is the point. Wrong for money, and wrong
  for opinions about dirt.
- **`timestamptz`, for any point in time.** The name is a lie, so I'll say it
  first: it does not store a time zone. It stores an instant, and converts it
  for whoever's looking (your session's `TimeZone` setting). Plain `timestamp`
  stores a wall-clock reading with no reference point, so two rows can have the
  same value and mean different moments. That's not a bug you find. It's a bug
  you inherit.
- **`boolean`, for things that are actually yes or no.** A grudge has a
  direction, a severity, a beginning and an end. None of that is yes or no.
  That's a table, and we're going to build it.
- **`bigint` ids, generated as identity.** `int` is fine, right up until it
  runs out at about 2.1 billion, and then it's an outage. The saving is small.
  The failure is not. `GENERATED ALWAYS AS IDENTITY` has superseded `serial`;
  if a tutorial says `serial`, use this instead.
- **Enums, for a short, fixed ladder.** Cheap, readable, ordered. (You can add
  values later, but you can't remove them, so keep the ladder short.) We'll use
  two.
- **`jsonb`, for a genuinely unknown shape.** The `misc` column was `jsonb`
  without the honesty.

> Postgres wants you to tell it what things are. A vague type is not a
> decision you avoided. It's a decision you deferred, with interest.

Those are the parts. Now the shape.

---

## 6 · Worms and tunnels

Two real tables. Things that exist once, in one place, with one spelling.

```
\i 02-worms-and-tunnels.sql
```

```sql
CREATE TABLE worms (
  id        bigint GENERATED ALWAYS
            AS IDENTITY PRIMARY KEY,
  name      text    NOT NULL,
  length_mm numeric(5,1),
  is_me     boolean NOT NULL DEFAULT false,

  CHECK (length_mm > 0)
);
```

Every worm gets an id. That's a **primary key**, and if you've seen those
words and never been told what they mean, it's this: a value that never
changes and is never reused. Everything else in the database is going to point
at it.

`name` is `text` now. Which means the Duke is restored.

The `CHECK` says a worm's length has to be positive. I didn't need a comment
to say that. The database says it.

```sql
CREATE TABLE tunnels (
  id             bigint GENERATED ALWAYS
                 AS IDENTITY PRIMARY KEY,
  name           text   NOT NULL UNIQUE,
  dug_by_worm_id bigint NOT NULL
                 REFERENCES worms(id),
  depth_cm       numeric(5,1),
  dug_at         timestamptz
);
```

Two things to look at here:

- **`name text NOT NULL UNIQUE`.** There is now exactly one row that means The
  Long Dark. Rename it once and everything follows, because nothing else
  stores the name at all. That's the whole fix for failure three.
- **`dug_by_worm_id ... REFERENCES worms(id)`.** That's a **foreign key**.
  Every tunnel was dug by exactly one worm; one worm can dig many tunnels. That
  shape is called **one-to-many**, and it's probably the most common
  relationship in every database you'll ever touch.

The file puts in seven worms and six tunnels, then shows who dug what:

```
      tunnel       |                         dug_by                          | depth_cm
-------------------+---------------------------------------------------------+----------
 By The Rock       | Mortimer                                                |     20.0
 Mudroom           | Stephen                                                 |     35.5
 Near The Old Root | me                                                      |     62.0
 that one place    | Greg?                                                   |
 The Escape Hatch  | me                                                      |     15.0
 The Long Dark     | Austin, Duke of the Long Dark Where I Do Not Go Anymore |    140.0
```

The Duke, in full. If you run `\d tunnels`, there's the foreign key at the
bottom, the way Postgres describes it:

```
Foreign-key constraints:
    "tunnels_dug_by_worm_id_fkey" FOREIGN KEY (dug_by_worm_id) REFERENCES worms(id)
```

Now let's watch what the foreign key actually does. Paste the statement from
`02a-break-the-fk.sql`:

```sql
INSERT INTO tunnels (name, dug_by_worm_id, depth_cm)
VALUES ('A Tunnel Dug By Nobody', 999, 10.0);
```

```
ERROR:  insert or update on table "tunnels" violates foreign key constraint "tunnels_dug_by_worm_id_fkey"
DETAIL:  Key (dug_by_worm_id)=(999) is not present in table "worms".
```

There is no worm 999. There never was. Postgres will not let me record a tunnel
dug by a worm who doesn't exist.

The database has more integrity than I do.

And read the `DETAIL` line: Postgres tells you exactly which key and which
table. Its error messages are some of the better ones out there, so get in the
habit of reading them.

That's the thing to understand about a foreign key. It's not bookkeeping. It's
the database refusing to write down something that cannot be true. And
`NOT NULL`, and `UNIQUE`, and that `CHECK` on length are the same idea in three
other shapes.

> Constraints are documentation the database actually enforces. A comment
> tells the next person what you meant. A constraint makes it impossible to
> mean anything else.

---

## 7 · Dirt tastings: a join table with its own facts

Worms exist. Tunnels exist. Every tunnel knows who dug it. But I didn't just
dig these tunnels. I ate in them. And so did everyone else.

A worm eats dirt in many tunnels. A tunnel gets eaten in by many worms. Where
does that go? Not on `worms`: which tunnel? Not on `tunnels`: which worm?
Neither table can hold it. So the relationship gets its own table.

First, an enum:

```sql
CREATE TYPE dirt_texture AS ENUM (
  'loamy',
  'gritty',
  'suspiciously_damp',
  'concerning'
);
```

Four textures of dirt. Three of those describe the dirt. The fourth describes
me. That's what an enum is: the list of categories you decided were worth
telling apart. And in Postgres an enum is a real type, made with
`CREATE TYPE`, so any table can use it.

```sql
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
```

Two foreign keys. One to `worms`, one to `tunnels`. That's the whole trick.

But look what happened while we were doing it. The relationship turned out to
have its own facts. When I ate it. What I thought. How damp it was. The
interesting thing was never the worm, and it was never the tunnel. It was the
opinion. This join table is the most interesting table we've got.

And `rating` is `numeric(3,1)`. Deliberately. After what `real` did to us.

```
\i 03-dirt-tastings.sql
```

The file ends with the same question I asked in failure two. Is 4.1 equal to
4.1?

```
 rating | is 4.1 equal to 4.1
--------+---------------------
    4.1 | t
```

Yes. `numeric` stored the number I typed. We love that.

> This is called a join table. When two things relate to each other
> many-to-many, the relationship becomes its own table. You'll do this
> constantly, for the rest of your career, in every database you ever touch.

---

## 8 · Grudges: a worm, pointing at a worm

Now. The thing we came here for.

```
\i 04-grudges.sql
```

The file does two things: a warm-up, then the grudges table.

### Warm-up: Stephen

Before the hard one, a warm-up. One column. A worm, pointing at a worm.

```sql
ALTER TABLE worms
    ADD COLUMN IF NOT EXISTS introduced_by_worm_id bigint REFERENCES worms(id);

UPDATE worms
SET introduced_by_worm_id = (SELECT id FROM worms WHERE name = 'Stephen')
WHERE name <> 'Stephen';
```

Every worm I know was introduced by Stephen. Stephen knows every worm. And
nobody knows who introduced Stephen:

```sql
SELECT name FROM worms
WHERE introduced_by_worm_id IS NULL;
```

```
  name
---------
 Stephen
```

He's the only NULL. That's what a nullable column is for: this recursion has to
stop somewhere.

(It's `IS NULL`, not `= NULL`. NULL means "unknown", so `= NULL` is never
true, and you'd get no rows back at all.)

### The grudges table

Now let's do what we did with dirt tastings, but both foreign keys point where
Stephen's does.

```sql
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
```

Going through it:

- **`wronged_worm_id`, `offending_worm_id`.** Two foreign keys, both to
  `worms`. The grudge knows its direction now. That's the thing the boolean
  never could do.
- **`reason text NOT NULL`.** You cannot hold a grudge you cannot articulate.
  That is a policy decision, enforced by the database.
- **`severity`.** Mild, simmering, generational (that's our second enum).
  Worms don't live that long.
- **`formed_at`, defaulting to now.** Because "when did it start" was one of
  the four things we wanted to know.
- **`resolved_at`, nullable.** NULL means it's still going.
- **The primary key is the pair.** One grudge per worm per worm.
- **And a `CHECK`.** You cannot hold a grudge against yourself.

The file ends by listing the five grudges it created:

```
 wronged  | offending |   severity   |                   reason
----------+-----------+--------------+--------------------------------------------
 me       | Chelsea   | generational | inherited. the soil remembers. I do not.
 me       | Tommy     | generational | did not come to NYC
 Tommy    | me        | simmering    | unclear. he has not said. he will not say.
 Mortimer | Greg?     | mild         | rated the Mudroom a 3 without elaborating
 Chelsea  | Stephen   | mild         | brought something back from the Long Dark
```

If you run `\d grudges`, notice that Postgres already made an index here,
called `grudges_pkey`. Hold that thought; it comes back in section 10.

Now let's break it. Paste the three statements from
`04a-break-the-constraints.sql`, one at a time.

**A grudge against yourself:**

```sql
INSERT INTO grudges (wronged_worm_id, offending_worm_id, severity, reason)
SELECT id, id, 'generational', 'I should have known'
FROM worms WHERE name = 'me';
```

```
ERROR:  new row for relation "grudges" violates check constraint "grudges_check"
```

The worm tries anyway.

**A grudge you can't articulate:**

```sql
INSERT INTO grudges (wronged_worm_id, offending_worm_id, severity, reason)
SELECT a.id, b.id, 'simmering', NULL
FROM worms a, worms b WHERE a.name = 'me' AND b.name = 'Mortimer';
```

```
ERROR:  null value in column "reason" of relation "grudges" violates not-null constraint
```

Can't articulate it, can't file it.

**A second grudge against the same worm:**

```sql
INSERT INTO grudges (wronged_worm_id, offending_worm_id, severity, reason)
SELECT a.id, b.id, 'generational', 'still did not come to NYC'
FROM worms a, worms b WHERE a.name = 'me' AND b.name = 'Tommy';
```

```
ERROR:  duplicate key value violates unique constraint "grudges_pkey"
DETAIL:  Key (wronged_worm_id, offending_worm_id)=(1, 3) already exists.
```

One grudge per worm per worm. That's the primary key: it's the pair. If Tommy
wrongs me again, I don't file a second grudge. I escalate the one I have.
(There's an `UPDATE` for that in the comments of `04a`.)

That's a **self-referencing many-to-many**: anything where a thing relates to
many other things of the same kind. Followers, friendships, social graphs. Org
charts and comment threads are the one-to-many version; that's Stephen's
column. It's the same pattern every single time, and we've built one.

Here's the worm's entire life (that we know of). Every line is a foreign key:

```mermaid
erDiagram
    worms ||--o{ tunnels : "dug_by_worm_id"
    worms ||--o{ dirt_tastings : "worm_id"
    tunnels ||--o{ dirt_tastings : "tunnel_id"
    worms ||--o{ grudges : "wronged_worm_id"
    worms ||--o{ grudges : "offending_worm_id"
    worms |o--o{ worms : "introduced_by_worm_id"
```

Four tables. Let's ask it something.

---

## 9 · Asking the question you meant

Paste the four queries from `05-queries.sql`, one at a time.

### Who do I owe an apology to?

```sql
SELECT w.name          AS wronged_worm,
       g.severity,
       g.reason,
       g.formed_at::date AS since
FROM grudges g
JOIN worms w ON w.id = g.wronged_worm_id
WHERE g.offending_worm_id = (SELECT id FROM worms WHERE is_me)
  AND g.resolved_at IS NULL
ORDER BY g.formed_at;
```

```
 wronged_worm | severity  |                   reason                   |   since
--------------+-----------+--------------------------------------------+------------
 Tommy        | simmering | unclear. he has not said. he will not say. | 2026-01-04
```

Against the table I made at 3am, this was unanswerable: there was no column
for who the grudge was against. Now it's a join. And `resolved_at IS NULL` is
the whole filter. NULL means it's still going.

### Which tunnel has the best dirt?

```sql
SELECT t.name                   AS tunnel,
       count(*)                 AS tastings,
       round(avg(d.rating), 2)  AS avg_rating
FROM dirt_tastings d
JOIN tunnels t ON t.id = d.tunnel_id
GROUP BY t.name
ORDER BY avg_rating DESC;
```

```
      tunnel       | tastings | avg_rating
-------------------+----------+------------
 Near The Old Root |        1 |       4.10
 Mudroom           |        3 |       3.63
 The Long Dark     |        5 |       3.58
 By The Rock       |        2 |       3.50
```

The tunnel name used to be a comma-separated string in three spellings, and
the rating used to be a float. Now it's a `GROUP BY`, and the average is clean
because it's `numeric`.

Now read the top and bottom rows. The dirt near the old root is better than the
dirt by the rock. I said that at the very beginning, on nothing but a feeling.
The data agrees.

### Which tunnels have I dug but never eaten in?

```sql
SELECT t.name AS tunnel_i_dug_and_never_ate_in
FROM tunnels t
LEFT JOIN dirt_tastings d
       ON d.tunnel_id = t.id
      AND d.worm_id   = (SELECT id FROM worms WHERE is_me)
WHERE t.dug_by_worm_id = (SELECT id FROM worms WHERE is_me)
  AND d.id IS NULL;
```

```
 tunnel_i_dug_and_never_ate_in
-------------------------------
 The Escape Hatch
```

This one's a `LEFT JOIN`, which means: give me every tunnel, even the ones
with nothing on the other side. Then `WHERE ... IS NULL` keeps only the ones
with nothing. The absence is the answer.

The Escape Hatch. Dug at ten past three in the morning. Never used.

### What do we owe each other?

```sql
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
```

```
         direction         |  worm   |   severity   |                   reason                   |   since    | resolved_at
---------------------------+---------+--------------+--------------------------------------------+------------+-------------
 I hold this against them  | Chelsea | generational | inherited. the soil remembers. I do not.   | 2025-08-15 |
 I hold this against them  | Tommy   | generational | did not come to NYC                        | 2026-01-04 |
 they hold this against me | Tommy   | simmering    | unclear. he has not said. he will not say. | 2026-01-04 |
```

Same table, asked two questions, stacked. That's all `UNION ALL` does. The
first half asks about `wronged_worm_id`, the second asks about
`offending_worm_id`. Same rows, read from two directions.

And there's Tommy. Twice. Once in each direction. Neither one resolved.

At the very beginning, this was a feeling. Now it's a row, with a direction, a
severity, a start date, and a very conspicuous empty space where the ending
goes.

---

## 10 · Making it faster is someone else's problem

Every question we just asked came back instantly. That's because there are
about thirty rows in the whole database. Let's talk about what happens when
there are a lot more.

```
\i 06-indexes.sql
```

**Run this file last.** It adds two hundred thousand worms (more than we really
need) and about as many grudges, because five grudges would never give us a
real query plan to look at. Then it runs three `EXPLAIN ANALYZE`s. These plans
are from Postgres 18, trimmed to the interesting lines.

**1. What grudges does worm 100,000 hold?**

```
Index Scan using grudges_pkey on grudges  (... rows=1.00 loops=1)
  Index Cond: (wronged_worm_id = 100000)
Execution Time: 0.029 ms
```

Index scan, instantly. And I never typed `CREATE INDEX`. The primary key on
`grudges` is the pair of worm ids, and Postgres backs every primary key with an
index. Most people's first index already exists and they don't know it.

**2. Same table, other direction: who's holding a grudge against worm
100,000?**

```
Seq Scan on grudges  (... rows=1.00 loops=1)
  Filter: (offending_worm_id = 100000)
  Rows Removed by Filter: 200003
Execution Time: 9.072 ms
```

Sequential scan: it read every row to find one. Look at that number.

Why? A composite index is sorted by its first column. Asking about the second
column alone is looking someone up in a phone book by their first name. The
book is sorted. Just not for that question.

(If you're wondering about Postgres 18's new skip scan: it can sometimes use a
multicolumn index without its first column, but only when that column has few
distinct values. This one has about 200,000, so we still get a seq scan.)

**3. Add the index, then ask again:**

```sql
CREATE INDEX grudges_offending_worm_id_idx ON grudges (offending_worm_id);
```

```
Index Scan using grudges_offending_worm_id_idx on grudges  (... rows=1.00 loops=1)
  Index Cond: (offending_worm_id = 100000)
Execution Time: 0.048 ms
```

Same query. Look at the number now: nine milliseconds down to about five
hundredths of one. Roughly two hundred times faster, on a laptop.

So what is an index, really?

> An index is a second copy of your data, sorted, that Postgres maintains for
> you.

That's why reads get fast and writes get slower. It's a tradeoff you can make
on a case-by-case basis. Indexes cost you on every write, they cost disk, and
adding them speculatively is how you get a slow database with great-looking
query plans.

B-tree is the default, and it's basically almost always right. The
[docs on index types](https://www.postgresql.org/docs/current/indexes-types.html)
are good. Making it faster is now, formally, someone else's problem.

---

## 11 · What the worm knows now

Same sentences. Same worm.

| What's true | Where it went |
|---|---|
| I am a worm. I have met other worms. | `worms`, and `introduced_by_worm_id` |
| I dig tunnels. Other worms dig tunnels. | `tunnels` |
| I eat dirt, and I have opinions about it. | `dirt_tastings` |
| I am holding grudges. Some are very old. | `grudges` |
| The dirt near the old root is better… | `rating`, `tunnel_id` |

Nouns became tables. Verbs became relationships. And that fifth sentence, the
one we added, didn't become a table at all. It became columns. Nouns give you
tables. Saying more gives you the columns.

The worm did not become an expert. The worm became someone who can look at a
schema, say why it's shaped that way, defend it, and change it when the next
true sentence comes along.

If you're interested in going further:

- **Run the repo. Break something on purpose.**
- **Read the Postgres docs on [data types](https://www.postgresql.org/docs/current/datatype.html).**
  Very solid documentation.
- **The next time you're about to make a table, write down some things you
  know, and some questions you want answers to.** Four sentences is plenty.

The worm persists.

---

## Starting over

```
docker compose down -v && docker compose up -d
```

That throws away the container and its data and starts you fresh. The only
advantage of amnesia.

## A few questions people ask

**Is `varchar` really the same as `text`?** In Postgres, yes: same storage,
same performance. The manual itself says to use `text` "rather than making up
an arbitrary length limit". If a length limit is a real rule, `varchar(n)` or a
`CHECK` constraint is fine.

**Why not UUIDs for ids?** They're the right call when ids get generated
outside the database, merged across systems, or shouldn't be guessable in a
URL. Random (v4) UUIDs scatter inserts all over the index; Postgres 18 has
`uuidv7()`, which is time-ordered and avoids most of that. For a first table,
`bigint` identity is simpler, and half the size.

**Is `serial` deprecated?** No. It still works, and the manual still documents
it. Identity columns are the SQL-standard replacement (since Postgres 10), and
they skip serial's awkward permission and dependency behavior.

**`json` or `jsonb`?** Almost always `jsonb`. It's stored parsed, it can be
indexed, and it supports containment queries. `json` keeps the exact text you
gave it, including key order and duplicate keys, which only matters if you
need those exact bytes back.

**Does `EXPLAIN ANALYZE` actually run the query?** Yes. Harmless for a
`SELECT`, but on an `UPDATE` or `DELETE` it really changes your data. Wrap it in
`BEGIN; ... ROLLBACK;` if you only want the plan.

**Can I add an index to a busy table?** A plain `CREATE INDEX` blocks writes
while it builds. In production, use `CREATE INDEX CONCURRENTLY`. It's slower,
but it doesn't block.

## Further reading

- [PostgreSQL docs: Data Types](https://www.postgresql.org/docs/current/datatype.html)
- [PostgreSQL docs: Constraints](https://www.postgresql.org/docs/current/ddl-constraints.html)
- [PostgreSQL docs: Index Types](https://www.postgresql.org/docs/current/indexes-types.html)
- [PostgreSQL wiki: Don't Do This](https://wiki.postgresql.org/wiki/Don%27t_Do_This)
