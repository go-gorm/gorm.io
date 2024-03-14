---
title: 上下文
layout: page
---

GORM 的上下文支持由 `WithContext` 方法启用，是一项强大的功能，可以增强 Go 应用程序中数据库操作的灵活性和控制力。 它允许在不同的操作模式、超时设置以及甚至集成到钩子/回调和中间件中进行上下文管理。 让我们从不同方面深入了解：

### 单会话模式

Single session mode is appropriate for executing individual operations. It ensures that the specific operation is executed within the context's scope, allowing for better control and monitoring.

```go
db.WithContext(ctx).Find(&users)
```

### Continuous Session Mode

Continuous session mode is ideal for performing a series of related operations. It maintains the context across these operations, which is particularly useful in scenarios like transactions.

```go
tx := db.WithContext(ctx)
tx.First(&user, 1)
tx.Model(&user).Update("role", "admin")
```

### Context Timeout

Setting a timeout on the context passed to `db.WithContext` can control the duration of long-running queries. This is crucial for maintaining performance and avoiding resource lock-ups in database interactions.

```go
ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
defer cancel()

db.WithContext(ctx).Find(&users)
```

### Hooks/Callbacks 中的 Context

The context can also be accessed within GORM's hooks/callbacks. This enables contextual information to be used during these lifecycle events.

```go
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
  ctx := tx.Statement.Context
  // ... use context
  return
}
```

### Integration with Chi Middleware

GORM's context support extends to web server middlewares, such as those in the Chi router. This allows setting a context with a timeout for all database operations within the scope of a web request.

```go
func SetDBMiddleware(next http.Handler) http.Handler {
  return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
    timeoutContext, _ := context.WithTimeout(context.Background(), time.Second)
    ctx := context.WithValue(r.Context(), "DB", db.WithContext(timeoutContext))
    next.ServeHTTP(w, r.WithContext(ctx))
  })
}

// Router setup
r := chi.NewRouter()
r.Use(SetDBMiddleware)

// Route handlers
r.Get("/", func(w http.ResponseWriter, r *http.Request) {
  db, ok := r.Context().Value("DB").(*gorm.DB)
  // ... db operations
})

r.Get("/user", func(w http.ResponseWriter, r *http.Request) {
  db, ok := r.Context().Value("DB").(*gorm.DB)
  // ... db operations
})
```

**Note**: Setting the `Context` with `WithContext` is goroutine-safe. This ensures that database operations are safely managed across multiple goroutines. For more details, refer to the [Session documentation](session.html) in GORM.

### Logger Integration

GORM's logger also accepts `Context`, which can be used for log tracking and integrating with existing logging infrastructures.

Refer to [Logger documentation](logger.html) for more details.
