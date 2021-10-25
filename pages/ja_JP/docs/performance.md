---
title: パフォーマンス
layout: page
---

GORMは、パフォーマンスを向上させるために多くの最適化を行っています。デフォルトのパフォーマンスはほとんどのアプリケーションにとって良いものとなっているでしょう。 しかし、アプリケーションのパフォーマンスを向上させるテクニックがまだいくつかあります。

## [デフォルトトランザクションを無効にする](transactions.html)

GORMはデータの一貫性を確保するために、書き込み操作（作成/更新/削除）をトランザクション内で実行します。これはパフォーマンスにとっては悪影響を及ぼしますが、初期化中に無効にすることも可能です。

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  SkipDefaultTransaction: true,
})
```

## [プリペアードステートメントをキャッシュする](session.html)

SQLを実行する際にプリペアードステートメントを作成し、以降の呼び出しを高速化するためにそれをキャッシュすることができます。

```go
// Globally mode
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  PrepareStmt: true,
})

// Session mode
tx := db.Session(&Session{PrepareStmt: true})
tx.First(&user, 1)
tx.Find(&users)
tx.Model(&user).Update("Age", 18)
```

{% note warn %}
**注** ラウンドトリップを減らすためにMySQLのinterpolateparamsを有効にする方法も参照するとよいでしょう。 https://github.com/go-sql-driver/mysql#interpolateparams
{% endnote %}

### [プリペアードステートメントを用いたSQL Builder](sql_builder.html)

プリペアードステートメントは RAW SQL とも併用できます。例：

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  PrepareStmt: true,
})

db.Raw("select sum(age) from users where role = ?", "admin").Scan(&age)
```

You can also use GORM API to prepare SQL with [DryRun Mode](session.html), and execute it with prepared statement later, checkout [Session Mode](session.html) for details

## Select Fields

By default GORM select all fields when querying, you can use `Select` to specify fields you want

```go
db.Select("Name", "Age").Find(&Users{})
```

Or define a smaller API struct to use the [smart select fields feature](advanced_query.html)

```go
type User struct {
  ID     uint
  Name   string
  Age    int
  Gender string
  // hundreds of fields
}

type APIUser struct {
  ID   uint
  Name string
}

// Select `id`, `name` automatically when query
db.Model(&User{}).Limit(10).Find(&APIUser{})
// SELECT `id`, `name` FROM `users` LIMIT 10
```

## [Iteration / FindInBatches](advanced_query.html)

Query and process records with iteration or in batches

## [Index Hints](hints.html)

[Index](indexes.html) is used to speed up data search and SQL query performance. `Index Hints` gives the optimizer information about how to choose indexes during query processing, which gives the flexibility to choose a more efficient execution plan than the optimizer

```go
import "gorm.io/hints"

db.Clauses(hints.UseIndex("idx_user_name")).Find(&User{})
// SELECT * FROM `users` USE INDEX (`idx_user_name`)

db.Clauses(hints.ForceIndex("idx_user_name", "idx_user_id").ForJoin()).Find(&User{})
// SELECT * FROM `users` FORCE INDEX FOR JOIN (`idx_user_name`,`idx_user_id`)"

db.Clauses(
    hints.ForceIndex("idx_user_name", "idx_user_id").ForOrderBy(),
    hints.IgnoreIndex("idx_user_name").ForGroupBy(),
).Find(&User{})
// SELECT * FROM `users` FORCE INDEX FOR ORDER BY (`idx_user_name`,`idx_user_id`) IGNORE INDEX FOR GROUP BY (`idx_user_name`)"
```

## Read/Write Splitting

Increase data throughput through read/write splitting, check out [Database Resolver](dbresolver.html)
