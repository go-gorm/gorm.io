---
title: DBResolver
layout: page
---

DBResolverはGORMの複数データベースへの対応を可能としています。以下の機能がサポートされています。

* 複数DB/レプリカへの接続対応
* 読み取り/書き込みの分離
* テーブルや構造体に基づいた自動での接続切替
* 手動での接続切替
* プライマリやレプリカへのロードバランシング
* 素のSQLでの動作

https://github.com/go-gorm/dbresolver

## 使用方法

```go
import (
  "gorm.io/gorm"
  "gorm.io/plugin/dbresolver"
  "gorm.io/driver/mysql"
)

db, err := gorm.Open(mysql.Open("db1_dsn"), &gorm.Config{})

db.Use(dbresolver.Register(dbresolver.Config{
  // use `db2` as sources, `db3`, `db4` as replicas
  Sources:  []gorm.Dialector{mysql.Open("db2_dsn")},
  Replicas: []gorm.Dialector{mysql.Open("db3_dsn"), mysql.Open("db4_dsn")},
  // sources/replicas load balancing policy
  Policy: dbresolver.RandomPolicy{},
}).Register(dbresolver.Config{
  // use `db1` as sources (DB's default connection), `db5` as replicas for `User`, `Address`
  Replicas: []gorm.Dialector{mysql.Open("db5_dsn")},
}, &User{}, &Address{}).Register(dbresolver.Config{
  // use `db6`, `db7` as sources, `db8` as replicas for `orders`, `Product`
  Sources:  []gorm.Dialector{mysql.Open("db6_dsn"), mysql.Open("db7_dsn")},
  Replicas: []gorm.Dialector{mysql.Open("db8_dsn")},
}, "orders", &Product{}, "secondary"))
```

## トランザクション

トランザクションを使用する場合、DBResolverは同一接続内でのトランザクションを使用するため、接続先の切り替えは行われません。

## 接続の自動切替

テーブル/構造体に基づいて自動的に接続を切り替えることができます。

素のSQLの場合は、SQLからテーブル名を抽出してDBResolverの設定を参照します。また、SQL文が (`SELECT... FOR UPDATE` 以外の) `SELECT` で始まるSQLでなければ、Sourcesで指定したDBが使用されます。 例:

```go
// `User` Resolver Examples
db.Table("users").Rows() // replicas `db5`
db.Model(&User{}).Find(&AdvancedUser{}) // replicas `db5`
db.Exec("update users set name = ?", "jinzhu") // sources `db1`
db.Raw("select name from users").Row().Scan(&name) // replicas `db5`
db.Create(&user) // sources `db1`
db.Delete(&User{}, "name = ?", "jinzhu") // sources `db1`
db.Table("users").Update("name", "jinzhu") // sources `db1`

// Global Resolver Examples
db.Find(&Pet{}) // replicas `db3`/`db4`
db.Save(&Pet{}) // sources `db2`

// Orders Resolver Examples
db.Find(&Order{}) // replicas `db8`
db.Table("orders").Find(&Report{}) // replicas `db8`
```

## 読み取り/書き込みの分離

現在使用されている [GORM callbacks](https://gorm.io/docs/write_plugins.html) に基づいて、DBResolverで読み取り/書き込みを分離できます。

`Query` や `Row` のコールバックでは、 `Write Model` が指定されていない限り `レプリカ` が使用されます。 `Raw` コールバックについては、SQLが `SELECT` で始まり読み込み処理のみと判断された場合は `レプリカ` が使用されます。

## 手動での接続切替

```go
// Write Modeを使用する：`db1`からuserレコードを読み込む
db.Clauses(dbresolver.Write).First(&user)

// Resolverを指定する：`secondary` のレプリカである db8 から userレコードを読み込む
db.Clauses(dbresolver.Use("secondary")).First(&user)

// Resolverを指定 かつ Write Modeを使用する：`secondary` のデータソースである db6 または db7 からuserレコードを読み込む
db.Clauses(dbresolver.Use("secondary"), dbresolver.Write).First(&user)
```

## 負荷分散

GORMは、ポリシーに基づいたロードバランシングをサポートしています。ポリシーを定めるには、以下のインターフェイスを実装する構造体を用意する必要があります。

```go
type Policy interface {
    Resolve([]gorm.ConnPool) gorm.ConnPool
}
```

現在は `RandomPolicy` のみ実装されています。他のポリシーが指定されていない場合はこれがデフォルトのオプションとなります。

## コネクションプール

```go
db.Use(
  dbresolver.Register(dbresolver.Config{ /* xxx */ }).
  SetConnMaxIdleTime(time.Hour).
  SetConnMaxLifetime(24 * time.Hour).
  SetMaxIdleConns(100).
  SetMaxOpenConns(200)
)
```
