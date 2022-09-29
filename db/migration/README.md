# migrate

```shell
$ brew install golang-migrate

$ migrate create -ext sql -dir db/migration -seq init_schema

/Users/kiyota/gitdir/golang/simplebank/db/migration/000001_init_schema.up.sql
/Users/kiyota/gitdir/golang/simplebank/db/migration/000001_init_schema.down.sql

$ migrate -path db/migration -database "postgresql://postgres:password@localhost:5432/simple-bank?sslmode=disable" -verbose up

2022/08/31 08:43:49 Start buffering 1/u init_schema
2022/08/31 08:43:49 Read and execute 1/u init_schema
2022/08/31 08:43:49 Finished 1/u init_schema (read 40.333667ms, ran 215.14325ms)
2022/08/31 08:43:49 Finished after 264.348709ms
2022/08/31 08:43:49 Closing source and database
```

```shell
$ migrate create -ext sql -dir db/migration -seq add_users
```

## check constraint

```sql
SELECT conrelid::regclass AS table_from
     , conname
     , pg_get_constraintdef(c.oid)
FROM pg_constraint c
         JOIN pg_namespace n ON n.oid = c.connamespace
WHERE contype IN ('f', 'p ', 'u')
  AND n.nspname = 'public' -- your schema here
ORDER BY conrelid::regclass::text, contype DESC;
```