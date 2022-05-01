---
title: DBResolver
layout: page
---

DBResolver 为 GORM 提供了多个数据库支持，支持以下功能：

* 支持多个 sources、replicas
* 读写分离
* 根据工作表、struct 自动切换连接
* 手动切换连接
* Sources/Replicas 负载均衡
* 适用于原生 SQL
* Transaction

https://github.com/go-gorm/dbresolver

## 用法

```go
import (
  "gorm.io/gorm"
  "gorm.io/plugin/dbresolver"
  "gorm.io/driver/mysql"
)

db, err := gorm.Open(mysql.Open("db1_dsn"), &gorm.Config{})

db.Use(dbresolver.Register(dbresolver.Config{
  // `db2` 作为 sources，`db3`、`db4` 作为 replicas
  Sources:  []gorm.Dialector{mysql.Open("db2_dsn")},
  Replicas: []gorm.Dialector{mysql.Open("db3_dsn"), mysql.Open("db4_dsn")},
  // sources/replicas 负载均衡策略
  Policy: dbresolver.RandomPolicy{},
}).Register(dbresolver.Config{
  // `db1` 作为 sources（DB 的默认连接），对于 `User`、`Address` 使用 `db5` 作为 replicas
  Replicas: []gorm.Dialector{mysql.Open("db5_dsn")},
}, &User{}, &Address{}).Register(dbresolver.Config{
  // `db6`、`db7` 作为 sources，对于 `orders`、`Product` 使用 `db8` 作为 replicas
  Sources:  []gorm.Dialector{mysql.Open("db6_dsn"), mysql.Open("db7_dsn")},
  Replicas: []gorm.Dialector{mysql.Open("db8_dsn")},
}, "orders", &Product{}, "secondary"))
```

## Automatic connection switching

DBResolver will automatically switch connection based on the working table/struct

For RAW SQL, DBResolver will extract the table name from the SQL to match the resolver, and will use `sources` unless the SQL begins with `SELECT` (excepts `SELECT... FOR UPDATE`), for example:

```go
// `User` Resolver 示例
db.Table("users").Rows() // replicas `db5`
db.Model(&User{}).Find(&AdvancedUser{}) // replicas `db5`
db.Exec("update users set name = ?", "jinzhu") // sources `db1`
db.Raw("select name from users").Row().Scan(&name) // replicas `db5`
db.Create(&user) // sources `db1`
db.Delete(&User{}, "name = ?", "jinzhu") // sources `db1`
db.Table("users").Update("name", "jinzhu") // sources `db1`

// Global Resolver 示例
db.Find(&Pet{}) // replicas `db3`/`db4`
db.Save(&Pet{}) // sources `db2`

// Orders Resolver 示例
db.Find(&Order{}) // replicas `db8`
db.Table("orders").Find(&Report{}) // replicas `db8`
```

## Read/Write Splitting

Read/Write splitting with DBResolver based on the current used [GORM callbacks](https://gorm.io/docs/write_plugins.html).

For `Query`, `Row` callback, will use `replicas` unless `Write` mode specified For `Raw` callback, statements are considered read-only and will use `replicas` if the SQL starts with `SELECT`

## Manual connection switching

```go
// 使用 Write 模式：从 sources db `db1` 读取 user
db.Clauses(dbresolver.Write).First(&user)

// 指定 Resolver：从 `secondary` 的 replicas db `db8` 读取 user
db.Clauses(dbresolver.Use("secondary")).First(&user)

// 指定 Resolver 和 Write 模式：从 `secondary` 的 sources db `db6` 或 `db7` 读取 user
db.Clauses(dbresolver.Use("secondary"), dbresolver.Write).First(&user)
```

## Transaction

When using transaction, DBResolver will keep using the transaction and won't switch to sources/replicas based on configuration

But you can specifies which DB to use before starting a transaction, for example:

```go
// Start transaction based on default replicas db
tx := DB.Clauses(dbresolver.Read).Begin()

// Start transaction based on default sources db
tx := DB.Clauses(dbresolver.Write).Begin()

// Start transaction based on `secondary`'s sources
tx := DB.Clauses(dbresolver.Use("secondary"), dbresolver.Write).Begin()
```

## 负载均衡

GORM supports load balancing sources/replicas based on policy, the policy should be a struct implements following interface:

```go
type Policy interface {
    Resolve([]gorm.ConnPool) gorm.ConnPool
}
```

Currently only the `RandomPolicy` implemented and it is the default option if no other policy specified.

## 连接池

```go
db.Use(
  dbresolver.Register(dbresolver.Config{ /* xxx */ }).
  SetConnMaxIdleTime(time.Hour).
  SetConnMaxLifetime(24 * time.Hour).
  SetMaxIdleConns(100).
  SetMaxOpenConns(200)
)
```
