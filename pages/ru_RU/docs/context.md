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

Режим непрерывной сессии обычно используется, когда вы хотите выполнить группу операций, например:

```go
tx := db.WithContext(ctx)
tx.First(&user, 1)
tx.Model(&user).Update("role", "admin")
```

## Таймаут контекста

Вы можете установить контекст с тайм-аутом в `db.WithContext`, чтобы установить тайм-аут для длительно выполняющихся запросов, например:

```go
ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
defer cancel()

db.WithContext(ctx).Find(&users)
```

## Контекст в Hooks/Callbacks

Вы можете получить доступ к объекту `Context` из текущего `Statement` объекта, например:

```go
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
  ctx := tx.Statement.Context
  // ...
  return
}
```

## Пример Chi Middleware

Режим непрерывного сеанса, который может быть полезен при обработке запросов API, например, вы можете настроить `*gorm.DB` с контекстом тайм-аута в middleware, а затем использовать `*gorm.DB` при обработке всех запросов

Ниже приведен пример Chi middleware:

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

  // много операций с базой данных
})

r.Get("/user", func(w http.ResponseWriter, r *http.Request) {
  db, ok := ctx.Value("DB").(*gorm.DB)

  var user User
  db.First(&user)

  //  много операций с базой данных
})
```

{% note %}
**ПРИМЕЧАНИЕ** Настройка `контекста` с помощью `WithContext` goroutine-safe, обратитесь к [Сессия](session.html) для получения подробной информации
{% endnote %}

## Logger

Logger также принимает ` контекст `, вы можете использовать его для отслеживания событий, обратитесь к [Logger](logger.html) для получения подробной информации
