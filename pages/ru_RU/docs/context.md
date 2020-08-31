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

## Пример Chi Middleware

Режим непрерывной сессии, который может оказаться полезным при обработке запросов API, например, можно настроить `*gorm. B` с контекстом таймаута в middlewares, а затем использовать `*gorm.DB` при обработке всех запросов

Пример middleware Chi:

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

  // много операций с БД
})

r.Get("/user", func(w http.ResponseWriter, r *http.Request) {
  db, ok := ctx.Value("DB").(*gorm.DB)

  var user User
  db.First(&user)

  // много операций с БД
})
```

{% note %}
**ПРИМЕЧАНИЕ** Установка `Context` с `WithContext` является goroutine-безопасным, смотрите [Сессии](session.html) для подробностей
{% endnote %}

## Logger

Logger также принимает `Context`, вы можете им отслеживать журналы, см. [Logger](logger.html) для подробностей
