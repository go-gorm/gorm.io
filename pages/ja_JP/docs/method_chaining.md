---
title: Method Chaining
layout: page
---

GORMはメソッドチェーンが可能なため、次のようなコードを書くことができます。

```go
db.Where("name = ?", "jinzhu").Where("age = ?", 18).First(&user)
```

GORMには `Chain Method`, `Finisher Method`, `New Session Method`という3種類のメソッドがあります:

## Chain Method

Chain Methodsは現在の`Statement`に`Clauses`を変更または追加するメソッドです。

`Where`, `Select`, `Omit`, `Joins`, `Scopes`, `Preload`, `Raw` (`Raw` can't be used with other chainable methods to build SQL)...

こちらが[Chain Methodの一覧](https://github.com/go-gorm/gorm/blob/master/chainable_api.go)です。`Clauses`についての詳細は [SQL Builder](sql_builder.html)を参照してください。

## <span id="finisher_method">Finisher Method</span>

Finishersは登録されたコールバックを実行する即時メソッドで、SQLを生成して実行します。

`Create`, `First`, `Find`, `Take`, `Save`, `Update`, `Delete`, `Scan`, `Row`, `Rows`...

[Finisher Methodの一覧](https://github.com/go-gorm/gorm/blob/master/finisher_api.go) を参照してください。

## New Session Mode

`*gorm.DB`が新しく初期化されたか、`New Session Method`が実行された後、 次のメソッド呼び出しは、現在のインスタンスを使用する代わりに新しい`Statement`インスタンスを作成します。

GORM defined `Session`, `WithContext`, `Debug` methods as `New Session Method`, refer [Session](session.html) for more details

以下の例で説明しましょう。

例１：

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
// db is new initialized *gorm.DB, which under `New Session Mode`
db.Where("name = ?", "jinzhu").Where("age = ?", 18).Find(&users)
// `Where("name = ?", "jinzhu")` is the first method call, it will creates a new `Statement`
// `Where("age = ?", 18)` reuse the `Statement`, and add conditions to the `Statement`
// `Find(&users)` is a finisher, it executes registered Query Callbacks, generate and run following SQL
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18;

db.Where("name = ?", "jinzhu2").Where("age = ?", 20).Find(&users)
// `Where("name = ?", "jinzhu2")` is also the first method call, it creates new `Statement` too
// `Where("age = ?", 20)` reuse the `Statement`, and add conditions to the `Statement`
// `Find(&users)` is a finisher, it executes registered Query Callbacks, generate and run following SQL
// SELECT * FROM users WHERE name = 'jinzhu2' AND age = 20;

db.Find(&users)
// `Find(&users)` is a finisher method and also the first method call for a `New Session Mode` `*gorm.DB`
// It creates a new `Statement` and executes registered Query Callbacks, generates and run following SQL
// SELECT * FROM users;
```

例：２

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
// db is new initialized *gorm.DB, which under `New Session Mode`
tx := db.Where("name = ?", "jinzhu")
// `Where("name = ?", "jinzhu")` is the first method call, it creates a new `Statement` and add conditions

tx.Where("age = ?", 18).Find(&users)
// `tx.Where("age = ?", 18)` REUSE above `Statement`, and add conditions to the `Statement`
// `Find(&users)` is a finisher, it executes registered Query Callbacks, generate and run following SQL
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18

tx.Where("age = ?", 28).Find(&users)
// `tx.Where("age = ?", 18)` REUSE above `Statement` also, and add conditions to the `Statement`
// `Find(&users)` is a finisher, it executes registered Query Callbacks, generate and run following SQL
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18 AND age = 20;
```

{% note warn %}
**NOTE** In example 2, the first query affected the second generated SQL as GORM reused the `Statement`, this might cause unexpected issues, refer [Goroutine Safety](#goroutine_safe) for how to avoid it
{% endnote %}

## <span id="goroutine_safe">Method Chain Safety/Goroutine Safety</span>

Methods will create new `Statement` instances for new initialized `*gorm.DB` or after a `New Session Method`, so to reuse a `*gorm.DB`, you need to make sure they are under `New Session Mode`, for example:

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})

// Safe for new initialized *gorm.DB
for i := 0; i < 100; i++ {
  go db.Where(...).First(&user)
}

tx := db.Where("name = ?", "jinzhu")
// NOT Safe as reusing Statement
for i := 0; i < 100; i++ {
  go tx.Where(...).First(&user)
}

ctx, _ := context.WithTimeout(context.Background(), time.Second)
ctxDB := db.WithContext(ctx)
// Safe after a `New Session Method`
for i := 0; i < 100; i++ {
  go ctxDB.Where(...).First(&user)
}

ctx, _ := context.WithTimeout(context.Background(), time.Second)
ctxDB := db.Where("name = ?", "jinzhu").WithContext(ctx)
// Safe after a `New Session Method`
for i := 0; i < 100; i++ {
  go ctxDB.Where(...).First(&user) // `name = 'jinzhu'` will apply to the query
}

tx := db.Where("name = ?", "jinzhu").Session(&gorm.Session{})
// Safe after a `New Session Method`
for i := 0; i < 100; i++ {
  go tx.Where(...).First(&user) // `name = 'jinzhu'` will apply to the query
}
```
