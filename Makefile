migrate-up:
	migrate -path db/migration -database "postgresql://postgres:password@localhost:5432/simple-bank?sslmode=disable" -verbose up

migrate-down:
	migrate -path db/migration -database "postgresql://postgres:password@localhost:5432/simple-bank?sslmode=disable" -verbose down

migrate-up-mysql:
	migrate -path db/migration/mysql -database "mysql://root:password@tcp(localhost:3306)/simple-bank" -verbose up

migrate-down-mysql:
	migrate -path db/migration/mysql -database "mysql://root:password@tcp(localhost:3306)/simple-bank" -verbose down

sqlc:
	sqlc generate

test:
	go test -v -cover ./...

server:
	go run main.go

mock:
	mockgen -build_flags=--mod=mod -package mockdb -destination db/mock/store.go github.com/kiyotakeshi/simplebank/db/sqlc Store

.PHONY: migrate-up migrate-down migrate-up-mysql migrate-down-mysql sqlc test server
