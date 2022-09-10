CREATE TABLE accounts (
                          id bigint auto_increment primary key,
                          owner varchar(50) NOT NULL,
                          balance bigint NOT NULL,
                          currency varchar(20) NOT NULL,
                          created_at timestamp NOT NULL DEFAULT (now())
);
