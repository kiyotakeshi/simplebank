- run MySQL container

```shell
$ docker compose up -d
```

```shell
# shell 1
$ docker compose exec mysql mysql -uroot -ppassword simple-bank

# this level is only applied this specific console session
mysql> select @@transaction_isolation;
+-------------------------+
| @@transaction_isolation |
+-------------------------+
| REPEATABLE-READ         |
+-------------------------+

# MySQL default transaction isolation level
mysql> select @@global.transaction_isolation;
+--------------------------------+
| @@global.transaction_isolation |
+--------------------------------+
| REPEATABLE-READ                |
+--------------------------------+
1 row in set (0.01 sec)
```

## read uncommitted

```shell
# shell 1
mysql> set session transaction isolation level read uncommitted;

mysql> select @@transaction_isolation;
+-------------------------+
| @@transaction_isolation |
+-------------------------+
| READ-UNCOMMITTED        |
+-------------------------+

mysql> select @@global.transaction_isolation;
+--------------------------------+
| @@global.transaction_isolation |
+--------------------------------+
| REPEATABLE-READ                |
+--------------------------------+

# begin;
mysql> start transaction;

mysql> select * from accounts;
+----+----------+---------+----------+---------------------+
| id | owner    | balance | currency | created_at          |
+----+----------+---------+----------+---------------------+
|  1 | mike     |     300 | JPY      | 2022-09-10 19:54:42 |
|  2 | kanye    |     500 | USD      | 2022-09-10 19:56:37 |
|  3 | kendrick |     700 | JPY      | 2022-09-10 19:56:37 |
+----+----------+---------+----------+---------------------+
```

```shell
# shell 2
mysql> set session transaction isolation level read uncommitted;

mysql> begin;

mysql> select * from accounts where id = 1;
+----+-------+---------+----------+---------------------+
| id | owner | balance | currency | created_at          |
+----+-------+---------+----------+---------------------+
|  1 | mike  |     300 | JPY      | 2022-09-10 19:54:42 |
+----+-------+---------+----------+---------------------+
```

in shell 1

```shell
mysql> update accounts set balance = balance - 10 where id = 1;

mysql> select * from accounts where id = 1;
+----+-------+---------+----------+---------------------+
| id | owner | balance | currency | created_at          |
+----+-------+---------+----------+---------------------+
|  1 | mike  |     290 | JPY      | 2022-09-10 19:54:42 |
+----+-------+---------+----------+---------------------+

# not committed yet
```

in shell 2 sees the changes made by transaction 1, `this is called dirty-read`

```shell
mysql> select * from accounts where id = 1;
+----+-------+---------+----------+---------------------+
| id | owner | balance | currency | created_at          |
+----+-------+---------+----------+---------------------+
|  1 | mike  |     290 | JPY      | 2022-09-10 19:54:42 |
+----+-------+---------+----------+---------------------+
```

---
## read committed

```shell
# shell 1
mysql> set session transaction isolation level read committed;

mysql> select @@transaction_isolation;
+-------------------------+
| @@transaction_isolation |
+-------------------------+
| READ-COMMITTED          |
+-------------------------+

mysql> begin;

mysql> select * from accounts where id = 1;
+----+-------+---------+----------+---------------------+
| id | owner | balance | currency | created_at          |
+----+-------+---------+----------+---------------------+
|  1 | mike  |     300 | JPY      | 2022-09-10 19:54:42 |
+----+-------+---------+----------+---------------------+
```

```shell
# shell 2

mysql> set session transaction isolation level read committed;

mysql> begin;
```

shell 1

```shell
mysql> update accounts set balance = balance - 10 where id = 1;

mysql> select * from accounts where id = 1;
+----+-------+---------+----------+---------------------+
| id | owner | balance | currency | created_at          |
+----+-------+---------+----------+---------------------+
|  1 | mike  |     290 | JPY      | 2022-09-10 19:54:42 |
+----+-------+---------+----------+---------------------+
```

shell 2, shell 1 transaction hasn't been committed yet.

`read-committed isolation level prevents dirty read phenomenon.`

```shell
mysql> select * from accounts where id = 1;
+----+-------+---------+----------+---------------------+
| id | owner | balance | currency | created_at          |
+----+-------+---------+----------+---------------------+
|  1 | mike  |     300 | JPY      | 2022-09-10 19:54:42 |
+----+-------+---------+----------+---------------------+
```

shell 1

```shell
mysql> commit;
```

shell 2, `same query returns different value, this is non-repeatable read phenomenon.`

```shell
mysql> select * from accounts where id = 1;
+----+-------+---------+----------+---------------------+
| id | owner | balance | currency | created_at          |
+----+-------+---------+----------+---------------------+
|  1 | mike  |     290 | JPY      | 2022-09-10 19:54:42 |
+----+-------+---------+----------+---------------------+
```

shell 1

```shell
mysql> begin;

mysql> update accounts set balance = balance - 10 where id = 1;
```

shell 2

```shell
mysql> select count(*) from accounts where balance >=290;
+----------+
| count(*) |
+----------+
|        3 |
+----------+
```

shell 1

```shell
mysql> commit;
```

shell 2, same query returns different set of row is returned. one row is disappeard due to other transaction.
`this is called phantom-read phenomenon`.

```shell
mysql> select count(*) from accounts where balance >=290;
+----------+
| count(*) |
+----------+
|        2 |
+----------+
```

read-committed isolation level can only prevent dirty read.
but still allows non-repeatable read and phantom-read phenomenon.

---
## repeatable read

```shell
# shell 1
mysql> set session transaction isolation level repeatable read;

mysql> select @@transaction_isolation;
+-------------------------+
| @@transaction_isolation |
+-------------------------+
| REPEATABLE-READ         |
+-------------------------+

mysql> begin;

mysql> select * from accounts;
+----+----------+---------+----------+---------------------+
| id | owner    | balance | currency | created_at          |
+----+----------+---------+----------+---------------------+
|  1 | mike     |     280 | JPY      | 2022-09-10 19:54:42 |
|  2 | kanye    |     500 | USD      | 2022-09-10 19:56:37 |
|  3 | kendrick |     700 | JPY      | 2022-09-10 19:56:37 |
```

```shell
# shell 2
mysql> set session transaction isolation level repeatable read;

mysql> begin;

mysql> select * from accounts where id = 1;
+----+-------+---------+----------+---------------------+
| id | owner | balance | currency | created_at          |
+----+-------+---------+----------+---------------------+
|  1 | mike  |     280 | JPY      | 2022-09-10 19:54:42 |
+----+-------+---------+----------+---------------------+

mysql> select count(*) from accounts where balance >=280;
+----------+
| count(*) |
+----------+
|        3 |
+----------+
```

shell 1(not committed yet)

```shell
mysql> update accounts set balance = balance - 10 where id = 1;

mysql> select * from accounts where id =1;
+----+-------+---------+----------+---------------------+
| id | owner | balance | currency | created_at          |
+----+-------+---------+----------+---------------------+
|  1 | mike  |     270 | JPY      | 2022-09-10 19:54:42 |
+----+-------+---------+----------+---------------------+
```

shell 2

```shell
mysql> select * from accounts where id = 1;
+----+-------+---------+----------+---------------------+
| id | owner | balance | currency | created_at          |
+----+-------+---------+----------+---------------------+
|  1 | mike  |     280 | JPY      | 2022-09-10 19:54:42 |
+----+-------+---------+----------+---------------------+

mysql> select count(*) from accounts where balance >=280;
+----------+
| count(*) |
+----------+
|        3 |
+----------+
```

shell 1 commit

```shell
mysql> commit;
```

shell 2, repeatable isolation level ensures that all read queries are repeatable.
even if there are changes made by other committed transactions.
so phantom read phenomenons is also prevented in this repeatable-read isolation level.

```shell
mysql> select * from accounts where id = 1;
+----+-------+---------+----------+---------------------+
| id | owner | balance | currency | created_at          |
+----+-------+---------+----------+---------------------+
|  1 | mike  |     280 | JPY      | 2022-09-10 19:54:42 |
+----+-------+---------+----------+---------------------+

mysql> select count(*) from accounts where balance >=280;
+----------+
| count(*) |
+----------+
|        3 |
+----------+
```

shell 2, update query exec

```shell
mysql> select * from accounts where id = 1;
+----+-------+---------+----------+---------------------+
| id | owner | balance | currency | created_at          |
+----+-------+---------+----------+---------------------+
|  1 | mike  |     280 | JPY      | 2022-09-10 19:54:42 |
+----+-------+---------+----------+---------------------+

mysql> update accounts set balance = balance - 10 where id = 1;

# by concurrent updates from other transactions, it prevented by serializable isolation level
mysql> select * from accounts where id = 1;
+----+-------+---------+----------+---------------------+
| id | owner | balance | currency | created_at          |
+----+-------+---------+----------+---------------------+
|  1 | mike  |     260 | JPY      | 2022-09-10 19:54:42 |
+----+-------+---------+----------+---------------------+
```

---
## serializable

```shell
# shell 1
mysql> set session transaction isolation level serializable;

mysql> select @@transaction_isolation;
+-------------------------+
| @@transaction_isolation |
+-------------------------+
| SERIALIZABLE            |
+-------------------------+

mysql> begin;
```

```shell
# shell 2
mysql> set session transaction isolation level serializable;

mysql> begin;
```

shell 2, select just account 1

```shell
mysql> select * from accounts where id = 1;
+----+-------+---------+----------+---------------------+
| id | owner | balance | currency | created_at          |
+----+-------+---------+----------+---------------------+
|  1 | mike  |     270 | JPY      | 2022-09-10 19:54:42 |
+----+-------+---------+----------+---------------------+
```

shell 1, update query for account 1 is blocked.

```shell
mysql> select * from accounts where id =1;
+----+-------+---------+----------+---------------------+
| id | owner | balance | currency | created_at          |
+----+-------+---------+----------+---------------------+
|  1 | mike  |     270 | JPY      | 2022-09-10 19:54:42 |
+----+-------+---------+----------+---------------------+

# update query is blocked
# MySQL implicitly converts all plain SELECT query to SELECT FOR SHARE
# only allows other transactions to READ the rows
mysql> update accounts set balance = balance - 10 where id = 1;
ERROR 1205 (HY000): Lock wait timeout exceeded; try restarting transaction

mysql> update accounts set balance = balance - 10 where id = 2;
Rows matched: 1  Changed: 1  Warnings: 0
```

