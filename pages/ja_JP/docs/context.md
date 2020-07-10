---
title: Context
layout: page
---

GORMはContextをサポートしています。メソッド `WithContext`で使用できます。

## 単一セッションモード

単一セッションモードは通常、単一の操作を実行するときに使用されます。

```go
db.WithContext(ctx).Find(&users)
```

## 連続セッションモード

連続セッションモードは、通常、一連の操作を実行するときに使用されます。例:

```go
tx := db.WithContext(ctx)
tx.First(&user, 1)
tx.Model(&user).Update("role", "admin")
```

## Chi Middleware の例

Continuous session mode which might be helpful when handling API requests, for example, you can set up `*gorm.DB` with Timeout Context in middlewares, and then use the `*gorm.DB` when processing all requests

Chi ミドルウェアの例を以下に示します。

```go
func SetDBMiddleware(next http.Handler) http.Handler {
  return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
    timeoutContext, _ := context.WithTimeout(context.Background(), time.Second)
    ctx := context.WithValue(r.Context(), "DB", db.WithContext(timeoutContext))
    next.ServeHTTP(w, r.WithContext(ctx))
  })
}

r := chi.NewRouter()
r.Use(SetDBMiddleware)

r.Get("/", func(w http.ResponseWriter, r *http.Request) {
  db, ok := ctx.Value("DB").(*gorm.DB)

  var users []User
  db.Find(&users)

  // lots of db operations
})

r.Get("/user", func(w http.ResponseWriter, r *http.Request) {
  db, ok := ctx.Value("DB").(*gorm.DB)

  var user User
  db.First(&user)

  // lots of db operations
})
```

**NOTE** Set `Context` with `WithContext` is goroutine-safe, refer [Session](session.html) for details

## Logger

Logger accepts `Context` too, you can it tracking logs, refer [Logger](logger.html) for details
