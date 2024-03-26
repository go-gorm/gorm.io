---
title: Contexto
layout: page
---

GORM's context support, enabled by the `WithContext` method, is a powerful feature that enhances the flexibility and control of database operations in Go applications. Isto possibilita o gerenciamento de contexto entre diferentes modos operacionais como configuração de timeout, integração entre hooks/callbacks e middlewares. Vamos nos aprofundar nestes diferentes aspectos:

### Modo de sessão única

Modo de sessão única é apropriado para executar operações simples. Isto garante que a operação específica seja executada no escopo do contexto, permitindo melhor controle e monitoramento.

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

### Context in Hooks/Callbacks

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

**Note**: Setting the `Context` with `WithContext` is goroutine-safe. . For more details, refer to the [Session documentation](session.html) in GORM.

### Integração com Logger

O GORM logger também aceita `Context`, que pode ser utilizado para log tracking e integração com a infraestrutura de log existente.

Consulte a [documentação do Logger](logger.html) para mais detalhes.
