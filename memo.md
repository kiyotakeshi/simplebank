```shell
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