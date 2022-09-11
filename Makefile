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

.PHONY: migrate-up migrate-down migrate-up-mysql migrate-down-mysql sqlc test server
