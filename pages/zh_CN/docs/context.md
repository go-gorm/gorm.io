---
title: Context
layout: page
---

GORM 通过 `WithContext` 方法提供了 Context 支持

## 单会话模式

单会话模式通常被用于执行单次操作

```go
db.WithContext(ctx).Find(&users)
```

## 持续会话模式

持续会话模式通常被用于执行一系列操作，例如：

```go
tx := db.WithContext(ctx)
tx.First(&user, 1)
tx.Model(&user).Update("role", "admin")
```

## Context 超时

对于长 Sql 查询，你可以传入一个带超时的 context 给 `db.WithContext` 来设置超时时间，例如：

```go
ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
defer cancel()

db.WithContext(ctx).Find(&users)
```

## Hooks/Callbacks 中的 Context

您可以从当前 `Statement`中访问 `Context` 对象，例如︰

```go
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
  ctx := tx.Statement.Context
  // ...
  return
}
```

## Chi 中间件示例

在处理 API 请求时持续会话模式会比较有用。例如，您可以在中间件中为 `*gorm.DB` 设置超时 Context，然后使用 `*gorm.DB` 处理所有请求

下面是一个 Chi 中间件的示例：

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

  // 你的其他 DB 操作...
})

r.Get("/user", func(w http.ResponseWriter, r *http.Request) {
  db, ok := ctx.Value("DB").(*gorm.DB)

  var user User
  db.First(&user)

  // 你的其他 DB 操作...
})
```

{% note %}
**注意** 通过 `WithContext` 设置的 `Context` 是线程安全的，参考[会话](session.html)获取详情
{% endnote %}

## Logger

Logger 也可以支持 `Context`，可用于日志追踪，查看 [Logger](logger.html) 获取详情
