---
title: Context
layout: page
---

GORMはContextをサポートしています。メソッド `WithContext`で使用できます。

## シングルセッション

シングルセッションは通常、単一の操作を実行するときに使用されます。

```go
db.WithContext(ctx).Find(&users)
```

## 継続セッション

継続セッションは、通常、一連の操作を実行するときに使用されます。例:

```go
tx := db.WithContext(ctx)
tx.First(&user, 1)
tx.Model(&user).Update("role", "admin")
```

## Context timeout

timeoutを設定したcontextを `db.WithContext` に渡すことで、時間がかかるクエリのタイムアウト時間を設定する事ができます。例：

```go
ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
defer cancel()

db.WithContext(ctx).Find(&users)
```

## Hooks/Callbacks内でのcontextの使用

`Statement` から `Context` にアクセスすることが可能です。例：

```go
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
  ctx := tx.Statement.Context
  // ...
  return
}
```

## Chi Middlewareの例

継続セッションはAPIリクエストの処理に役立ちます。例えば、ミドルウェア内でのタイムアウト設定をしたContextを使って、`*gorm.DB`を設定できます。 そして、その `*gorm.DB` を使ってリクエストの処理を行います。

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

{% note %}
**注** `WithContext`で`Context`を設定するのはゴルーチンセーフの処理です。 詳細は[Session](session.html)を参照してください。
{% endnote %}

## Logger

Loggerも `Context` もに対応しており、ログのトラッキングに使用することができます。詳細については [Logger](logger.html) を参照してください。
