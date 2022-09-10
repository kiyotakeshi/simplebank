## deadlock simulation 1

```shell
# shell1
$ docker compose exec postgres psql -U postgres -d simple-bank

simple-bank=# begin;
BEGIN
simple-bank=# select * from accounts where id = 1 for update;
id | owner | balance | currency |          created_at
----+-------+---------+----------+-------------------------------
1 | mike  |     100 | JPY      | 2022-09-01 14:33:41.599927+00
(1 row)

simple-bank=# update accounts set balance = 500 where id = 1;
UPDATE 1

simple-bank=# commit;
COMMIT
```

```shell
# shell2
$ docker compose exec postgres psql -U postgres -d simple-bank

simple-bank=# select * from accounts where id = 1 for update;

 id | owner | balance | currency |          created_at
----+-------+---------+----------+-------------------------------
  1 | mike  |     500 | JPY      | 2022-09-01 14:33:41.599927+00
(1 row)
```

```sql
-- check deadlock
select psa.datname,
       psa.application_name,
       pl.relation::regclass,
       pl.transactionid,
       pl.mode,
       pl.locktype,
       pl.granted,
       psa.usename,
       psa.query,
       psa.pid
from pg_stat_activity psa
join pg_locks pl on psa.pid = pl.pid
where psa.application_name = 'psql'
order by psa.pid;
```

---
## deadlock simulation 2

```shell
# shell1
$ docker compose exec postgres psql -U postgres -d simple-bank

simple-bank=# begin;
BEGIN

simple-bank=# update accounts set balance = balance - 10 where id = 1 returning *;
 id | owner  | balance | currency |          created_at
----+--------+---------+----------+-------------------------------
  1 | oeggah |     196 | EUR      | 2022-09-08 23:49:11.350992+00
(1 row)
```

```shell
# shell2
$ docker compose exec postgres psql -U postgres -d simple-bank

simple-bank=# begin;
BEGIN

simple-bank=# update accounts set balance = balance - 10 where id = 2 returning *;
 id | owner  | balance | currency |          created_at
----+--------+---------+----------+-------------------------------
  2 | oohofa |      92 | JPY      | 2022-09-08 23:49:11.372056+00
(1 row)

UPDATE 1
```

after that, in shell1

```shell
# shell1
# the query is blocked
simple-bank=# update accounts set balance = balance - 10 where id = 2 returning *;
```

```sql
-- check deadlock
select psa.datname,
       psa.application_name,
       pl.relation::regclass,
       pl.transactionid,
       pl.mode,
       pl.locktype,
       pl.granted,
       psa.usename,
       psa.query,
       psa.pid
from pg_stat_activity psa
join pg_locks pl on psa.pid = pl.pid
where psa.application_name = 'psql'
order by psa.pid;

/*
+-----------+----------------+------------------+-------------+----------------+-------------+-------+--------+--------------------------------------------------------------------+---+
|datname    |application_name|relation          |transactionid|mode            |locktype     |granted|usename |query                                                               |pid|
+-----------+----------------+------------------+-------------+----------------+-------------+-------+--------+--------------------------------------------------------------------+---+
|simple-bank|psql            |accounts_owner_idx|null         |RowExclusiveLock|relation     |true   |postgres|update accounts set balance = balance - 10 where id = 2 returning *;|86 |
|simple-bank|psql            |accounts_pkey     |null         |RowExclusiveLock|relation     |true   |postgres|update accounts set balance = balance - 10 where id = 2 returning *;|86 |
|simple-bank|psql            |accounts          |null         |RowExclusiveLock|relation     |true   |postgres|update accounts set balance = balance - 10 where id = 2 returning *;|86 |
|simple-bank|psql            |null              |null         |ExclusiveLock   |virtualxid   |true   |postgres|update accounts set balance = balance - 10 where id = 2 returning *;|86 |
|simple-bank|psql            |null              |855          |ShareLock       |transactionid|false  |postgres|update accounts set balance = balance - 10 where id = 2 returning *;|86 |
|simple-bank|psql            |null              |854          |ExclusiveLock   |transactionid|true   |postgres|update accounts set balance = balance - 10 where id = 2 returning *;|86 |
|simple-bank|psql            |accounts          |null         |ExclusiveLock   |tuple        |true   |postgres|update accounts set balance = balance - 10 where id = 2 returning *;|86 |
|simple-bank|psql            |null              |null         |ExclusiveLock   |virtualxid   |true   |postgres|update accounts set balance = balance - 10 where id = 2 returning *;|102|
|simple-bank|psql            |null              |855          |ExclusiveLock   |transactionid|true   |postgres|update accounts set balance = balance - 10 where id = 2 returning *;|102|
|simple-bank|psql            |accounts_owner_idx|null         |RowExclusiveLock|relation     |true   |postgres|update accounts set balance = balance - 10 where id = 2 returning *;|102|
|simple-bank|psql            |accounts_pkey     |null         |RowExclusiveLock|relation     |true   |postgres|update accounts set balance = balance - 10 where id = 2 returning *;|102|
|simple-bank|psql            |accounts          |null         |RowExclusiveLock|relation     |true   |postgres|update accounts set balance = balance - 10 where id = 2 returning *;|102|
+-----------+----------------+------------------+-------------+----------------+-------------+-------+--------+--------------------------------------------------------------------+---+  
*/
```

after that, in shell2

```shell
# shell2
simple-bank=# update accounts set balance = balance - 10 where id = 1 returning *;
ERROR:  deadlock detected
DETAIL:  Process 102 waits for ShareLock on transaction 854; blocked by process 86.
Process 86 waits for ShareLock on transaction 855; blocked by process 102.
HINT:  See server log for query details.
CONTEXT:  while updating tuple (0,34) in relation "accounts"
```

### to avoid lock, exec correct query order

```shell
# shell1
$ docker compose exec postgres psql -U postgres -d simple-bank

simple-bank=# begin;
BEGIN

simple-bank=# update accounts set balance = balance - 10 where id = 1 returning *;
 id | owner  | balance | currency |          created_at
----+--------+---------+----------+-------------------------------
  1 | oeggah |     196 | EUR      | 2022-09-08 23:49:11.350992+00
(1 row)
```

```shell
# shell2
$ docker compose exec postgres psql -U postgres -d simple-bank

simple-bank=# begin;
BEGIN

# waiting
simple-bank=# update accounts set balance = balance - 10 where id = 2 returning *;
```

```shell
# shell1
simple-bank=# update accounts set balance = balance - 10 where id = 2 returning *;
 id | owner  | balance | currency |          created_at
----+--------+---------+----------+-------------------------------
  1 | oeggah |     196 | EUR      | 2022-09-08 23:49:11.350992+00
(1 row)

simple-bank=# commit;
```

```shell
# shell2
# exec
simple-bank=# update accounts set balance = balance - 10 where id = 1 returning *;    
 id | owner  | balance | currency |          created_at
----+--------+---------+----------+-------------------------------
  1 | oeggah |     176 | EUR      | 2022-09-08 23:49:11.350992+00
(1 row)

UPDATE 1

simple-bank=# update accounts set balance = balance - 10 where id = 2 returning *;

simple-bank=# commit;
```
