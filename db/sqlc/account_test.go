package db

import (
	"context"
	"github.com/stretchr/testify/require"
	_ "github.com/stretchr/testify/require"
	"testing"
)

func TestCreateAccount(t *testing.T) {
	arg := CreateAccountParams{
		Owner:    "mike",
		Balance:  100,
		Currency: "JPY",
	}

	account, err := testQueries.CreateAccount(context.Background(), arg)
	require.NoError(t, err)
	require.NotEmpty(t, account)

	require.Equal(t, arg.Owner, account.Owner)
	require.Equal(t, arg.Balance, account.Balance)
	require.Equal(t, arg.Currency, account.Currency)

	require.NotZero(t, account.ID)
	require.NotZero(t, account.CreatedAt)
}
