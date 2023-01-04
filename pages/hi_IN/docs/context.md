---
title: Context
layout: page
---

GORM provides Context support, you can use it with method `WithContext`

## Single Session Mode

Single session mode usually used when you want to perform a single operation

```go
db.WithContext(ctx).Find(&users)
```

## Continuous session mode

Continuous session mode is usually used when you want to perform a group of operations, for example:

```go
tx := db.WithContext(ctx)
tx.First(&user, 1)
tx.Model(&user).Update("role", "admin")
```

## Context timeout

You can pass in a context with a timeout to `db.WithContext` to set timeout for long running queries, for example:

```go
ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
defer cancel()

db.WithContext(ctx).Find(&users)
```

## Context in Hooks/Callbacks

You can access the `Context` object from the current `Statement`, for example:

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
**NOTE** Setting `Context` with `WithContext` is goroutine-safe, refer [Session](session.html) for details
{% endnote %}

## Logger

Logger accepts `Context` too, you can use it for log tracking, refer [Logger](logger.html) for details
