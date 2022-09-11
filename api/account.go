package api

import (
	"github.com/gin-gonic/gin"
	db "github.com/kiyotakeshi/simplebank/db/sqlc"
	"net/http"
)

type createAccountRequest struct {
	Owner string `json:"owner" binding:"required"`
	// @see https://pkg.go.dev/github.com/go-playground/validator#hdr-One_Of
	Currency string `json:"currency" binding:"required,oneof=USD EUR JPY"`
}

func (server Server) createAccount(ctx *gin.Context) {
	var req createAccountRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	arg := db.CreateAccountParams{
		Owner:    req.Owner,
		Balance:  0,
		Currency: req.Currency,
	}
	account, err := server.store.CreateAccount(ctx, arg)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}

	ctx.JSON(http.StatusOK, account)
}
