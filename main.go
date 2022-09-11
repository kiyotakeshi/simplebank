package main

import (
	"database/sql"
	"github.com/kiyotakeshi/simplebank/api"
	db "github.com/kiyotakeshi/simplebank/db/sqlc"
	_ "github.com/lib/pq"
	"log"
)

const (
	dbDriver      = "postgres"
	dbSource      = "postgresql://postgres:password@localhost:5432/simple-bank?sslmode=disable"
	serverAddress = "0.0.0.0:8888"
)

func main() {
	conn, err := sql.Open(dbDriver, dbSource)
	if err != nil {
		log.Fatal("cannot connect to db:", err)
	}

	store := db.NewStore(conn)
	server := api.NewServer(store)

	err = server.Start(serverAddress)
	if err != nil {
		log.Fatal("connot start server:", err)
	}
}
