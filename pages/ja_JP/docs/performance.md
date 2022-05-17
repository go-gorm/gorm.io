---
title: パフォーマンス
layout: page
---

GORM optimizes many things to improve the performance, the default performance should be good for most applications, but there are still some tips for how to improve it for your application.

## [デフォルトトランザクションを無効にする](transactions.html)

GORM performs write (create/update/delete) operations inside a transaction to ensure data consistency, which is bad for performance, you can disable it during initialization

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

GORM APIを使用することも可能です。[DryRun Mode](session.html) を使用してSQLの準備を行い、後の処理でそのSQLをプリペアードステートメントとともに実行することができます。詳細については、[Session Mode](session.html) を参照してください。

## フィールドを選択する

デフォルトの設定では、クエリ実行時にすべてのフィールドが選択されます。 `Select` を使用して、必要なフィールドを指定できます。

```go
db.Select("Name", "Age").Find(&Users{})
```

または、 [便利なフィールドの選択](advanced_query.html) を使用するために、よりフィールド数を少なくした構造体を定義します。

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

イテレーションやバッチ処理でのクエリやレコード処理をすることも可能です。

## [インデックスヒント](hints.html)

[Index](indexes.html) はデータ検索とSQLクエリのパフォーマンスを高速化するために使用されます。 `Index Hints` は、クエリ処理で使用するべきインデックスの情報をオプティマイザに提供します。これにより、オプティマイザのものよりも効率的な実行計画を指定できるようになります。

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

## 読み取り/書き込みの分離

読み取り/書き込み処理の分離により、スループットを向上させることも可能です。詳細については [Database Resolover](dbresolver.html) を確認してください。
