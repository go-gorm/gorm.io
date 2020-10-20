---
title: Контекст
layout: страница
---

GORM обеспечивает поддержку контекста, вы можете использовать его методом `WithContext`

## Режим одной сессии

Режим одной сессии, обычно используется, когда вы хотите выполнить одну операцию

```go
db.WithContext(ctx).Find(&users)
```

## Режим непрерывной сессии

Режим непрерывной сессии обычно используется при выполнении группы операций, например:

```go
tx := db.WithContext(ctx)
tx.First(&user, 1)
tx.Model(&user).Update("role", "admin")
```

## Context in Hooks/Callbacks

You could access the `Context` object from current `Statement`, for example:

```go
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
  ctx := tx.Statement.Context
  // ...
  return
}
```

## Chi Middleware Example

Continuous session mode which might be helpful when handling API requests, for example, you can set up `*gorm.DB` with Timeout Context in middlewares, and then use the `*gorm.DB` when processing all requests

Following is a Chi middleware example:

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

{% note %}
**NOTE** Set `Context` with `WithContext` is goroutine-safe, refer [Session](session.html) for details
{% endnote %}

## Logger

Logger accepts `Context` too, you can use it for log tracking, refer [Logger](logger.html) for details
