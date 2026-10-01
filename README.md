# Would you still love me if I was a worm (who needed to learn Postgres)?

Postgres Summit US 2026 · Selena Flannery

**Pull the image before you get to the conference.** Conference wifi plus a
Postgres image is a two minute wait you do not want.

```
docker pull postgres:18
```

## Running it

```
docker compose up -d
psql postgresql://worm:worm@localhost:5432/worm
```

Then, inside `psql`:

```
\dt          -- list tables. currently: none. this is the worm's brain.
\d worms     -- describe a table
\q           -- leave
\i 00-the-3am-table.sql   -- run a file
```

That is all the Postgres operations knowledge this talk requires.

## The files

Run them in order, or jump to whichever number matches where the talk is.

Files ending in `a` hold the deliberate failures. Paste those one statement at
a time rather than running them with `\i` — each error is meant to land on its
own. `01-break-it.sql` is the same: never `\i` it.

| File | What it is |
|---|---|
| `00-the-3am-table.sql` | The bad table, seeded with mess |
| `01-break-it.sql` | Five ways it fails, and one thing Postgres lets you take back |
| `02-worms-and-tunnels.sql` | Real entities, real foreign keys |
| `02a-break-the-fk.sql` | The FK rejection — paste, don't `\i` |
| `03-dirt-tastings.sql` | A join table that carries its own data |
| `04-grudges.sql` | Self-referencing many-to-many |
| `04a-break-the-constraints.sql` | Three constraint rejections — paste, don't `\i` |
| `05-queries.sql` | Asking the questions you meant to ask |
| `06-indexes.sql` | Making it faster is someone else's problem |

## Starting over

```
docker compose down -v && docker compose up -d
```

The worm gets to start over. This is the only advantage of amnesia.
