package api

import (
	"errors"
	"math/bits"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/gotify/server/v2/auth"
	"github.com/gotify/server/v2/model"
)

func withID(ctx *gin.Context, name string, f func(id uint)) {
	if id, err := strconv.ParseUint(ctx.Param(name), 10, bits.UintSize); err == nil {
		f(uint(id))
	} else {
		ctx.AbortWithError(400, errors.New("invalid id"))
	}
}

// AppOwnedByUser reports whether app is non-nil and belongs to the
// authenticated user in ctx.  Extracted from repeated inline checks across
// message and application handlers.
func AppOwnedByUser(ctx *gin.Context, app *model.Application) bool {
	return app != nil && app.UserID == auth.GetUserID(ctx)
}
