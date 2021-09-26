---
title: Method Chaining
layout: page
---

GORMはメソッドチェーンが可能なため、次のようなコードを書くことができます。

```go
db.Where("name = ?", "jinzhu").Where("age = ?", 18).First(&user)
```

GORMには `Chain Method`, `Finisher Method`, `New Session Method` という3種類のメソッドがあります:

## Chain Method

Chain Methodsは現在の`Statement`を変更したり、`Clauses`を追加するメソッドです。

`Where`, `Select`, `Omit`, `Joins`, `Scopes`, `Preload`, `Raw` (`Raw` はSQLを生成する他のメソッドとは共用不可)... などがあります。

[Chain Methodの一覧](https://github.com/go-gorm/gorm/blob/master/chainable_api.go)はこちらです。`Clauses`についての詳細は [SQL Builder](sql_builder.html)を参照してください。

## <span id="finisher_method">Finisher Method</span>

Finisher Methodは登録されたコールバックを即時に実行するメソッドであり、この種類のメソッドが呼び出されるとSQLを生成して実行します。

`Create`, `First`, `Find`, `Take`, `Save`, `Update`, `Delete`, `Scan`, `Row`, `Rows`... などがあります。

こちらの [Finisher Methodの一覧](https://github.com/go-gorm/gorm/blob/master/finisher_api.go) も参照してください。

## New Session Mode

`*gorm.DB`が初期化された、あるいは、`New Session Method`が実行された場合、 その後のメソッド呼び出しは、現在の `Statement` インスタンスを使用せずに新しいインスタンスを作成します。

GROMは `Session`, `WithContext`, `Debug` を `New Session Method` として定義しています。詳細については [Session](session.html)を参照してください。

以下の例で説明しましょう。

例１：

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
// db は新規に初期化された *gorm.DB であるため、 `New Session Mode` に該当します
db.Where("name = ?", "jinzhu").Where("age = ?", 18).Find(&users)
// `Where("name = ?", "jinzhu")` が最初のメソッド呼び出しとなり、新規の `Statement` を作成します
// `Where("age = ?", 18)` は条件を追加した `Statement` を返却します
// `Find(&users)` はFinisher Methodであるため、登録されたクエリコールバックを呼び出し、以下のSQLを生成・実行します:
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18;

db.Where("name = ?", "jinzhu2").Where("age = ?", 20).Find(&users)
// `Where("name = ?", "jinzhu2")` が最初のメソッド呼び出しとなり、これも新規の `Statement` を作成します
// `Where("age = ?", 20)` は条件を追加した `Statement` を返却します
// `Find(&users)` はFinisher Methodであるため、登録されたクエリコールバックを呼び出し、以下のSQLを生成・実行します:
// SELECT * FROM users WHERE name = 'jinzhu2' AND age = 20;

db.Find(&users)
// `Find(&users)` はFinisher Methodであり、これが `New Session Mode` の `*gorm.DB` の最初のメソッド呼び出しとなります。
// 新しい `Statement` を作成し、登録されたクエリコールバックを呼び出し、以下のSQLを生成・実行します:
// SELECT * FROM users;
```

例２：

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
// db は新規に初期化された *gorm.DB であるため、 `New Session Mode` に該当します
tx := db.Where("name = ?", "jinzhu")
// `Where("name = ?", "jinzhu")` が最初のメソッド呼び出しとなり、新規の `Statement` を作成し条件を追加します

tx.Where("age = ?", 18).Find(&users)
// `tx.Where("age = ?", 18)` は上記の `Statement` を再利用し, 同じ `Statement` に条件を追加します
// `Find(&users)` はFinisher Methodであるため、登録されたクエリコールバックを呼び出し、以下のSQLを生成・実行します:
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18

tx.Where("age = ?", 28).Find(&users)
// `tx.Where("age = ?", 18)` は上記の `Statement` を再利用し, 同じ `Statement` に条件を追加します
// `Find(&users)` はFinisher Methodであるため、登録されたクエリコールバックを呼び出し、以下のSQLを生成・実行します:
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18 AND age = 28;
```

{% note warn %}
**注意** 例 2 では、GORMが `Statement` を再利用したため、最初のクエリが 2 番目の生成SQLに影響を与えています。 これは予期しない問題を引き起こす可能性があります。これを回避するには、 [Goroutine Safety](#goroutine_safe) を参照してください。
{% endnote %}

## <span id="goroutine_safe">Method Chain Safety/Goroutine Safety</span>

新規に初期化された `*gorm.DB` や `New Session Method` の後においては、メソッドを呼び出すと新しい `Statement` が生成されます。`*gorm.DB`を再利用する際は、 `New Session Mode` であることを確認する必要があります。例：

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})

// 新規に初期化された *gorm.DB であるため安全である
for i := 0; i < 100; i++ {
  go db.Where(...).First(&user)
}

tx := db.Where("name = ?", "jinzhu")
// Statementを使いまわしているため、安全ではない
for i := 0; i < 100; i++ {
  go tx.Where(...).First(&user)
}

ctx, _ := context.WithTimeout(context.Background(), time.Second)
ctxDB := db.WithContext(ctx)
// `New Session Method` の後であるため、安全である
for i := 0; i < 100; i++ {
  go ctxDB.Where(...).First(&user)
}

ctx, _ := context.WithTimeout(context.Background(), time.Second)
ctxDB := db.Where("name = ?", "jinzhu").WithContext(ctx)
//  `New Session Method` の後であるため、安全である
for i := 0; i < 100; i++ {
  go ctxDB.Where(...).First(&user) // `name = 'jinzhu'` が適用される
}

tx := db.Where("name = ?", "jinzhu").Session(&gorm.Session{})
//  `New Session Method` の後であるため、安全である
for i := 0; i < 100; i++ {
  go tx.Where(...).First(&user) // `name = 'jinzhu'` が適用される
}
```
