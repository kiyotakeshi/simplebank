postgres-up:
	docker compose up -d

postgres-down:
	docker compose down

migrate-up:
	migrate -path db/migration -database "postgresql://postgres:password@localhost:5432/simple-bank?sslmode=disable" -verbose up

migrate-down:
	migrate -path db/migration -database "postgresql://postgres:password@localhost:5432/simple-bank?sslmode=disable" -verbose down

sqlc:
	sqlc generate

.PHONY: postgres-up postgres-down migrate-up migrate-down sqlc
