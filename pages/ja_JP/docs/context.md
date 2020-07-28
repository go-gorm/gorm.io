---
title: Context
layout: page
---

GORMはContextをサポートしています。メソッド `WithContext`で使用できます。

## Single Session Mode

単一セッションモードは通常、単一の操作を実行するときに使用されます。

```go
db.WithContext(ctx).Find(&users)
```

## Continuous session mode

連続セッションモードは、通常、一連の操作を実行するときに使用されます。例:

```go
tx := db.WithContext(ctx)
tx.First(&user, 1)
tx.Model(&user).Update("role", "admin")
```

## Chi Middleware Example

継続セッションモードはAPIリクエストの処理に役立ちます。たとえば、ミドルウェア内のタイムアウトContextを使って、`*gorm.DB`を設定できます。 それからは、すべてのリクエストを処理するときにその`* gorm.DB`を使用します

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

  // データベースの処理を複数書く
})

r.Get("/user", func(w http.ResponseWriter, r *http.Request) {
  db, ok := ctx.Value("DB").(*gorm.DB)

  var user User
  db.First(&user)

  // データベースの処理を複数書く
})
```

**注** `Context`を`WithContext`で設定するのはgoroutine-safeです。 詳細は[Session](session.html)を参照してください。

## Logger

ロガーは `Context` も受け付けており、ログをトラッキングすることができます。詳細については [Logger](logger.html) を参照してください。
