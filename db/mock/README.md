```shell
$ mockgen -build_flags=--mod=mod -package mockdb -destination db/mock/store.go github.com/kiyotakeshi/simplebank/db/sqlc Store
```