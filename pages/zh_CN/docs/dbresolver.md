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

https://github.com/go-gorm/dbresolver

## 用法

```go
import (
  "gorm.io/gorm"
  "gorm.io/plugin/dbresolver"
  "gorm.io/driver/mysql"
)

DB, err := gorm.Open(mysql.Open("db1_dsn"), &gorm.Config{})

DB.Use(dbresolver.Register(dbresolver.Config{
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

## 事务

使用 transaction 时，DBResolver 也会使用一个事务，且不会切换 sources/replicas 连接

## 自动切换连接

DBResolver 会根据工作表、struct 自动切换连接

For RAW SQL, DBResolver will extract the table name from the SQL to match the resolver, and will use `sources` unless the SQL begins with `SELECT` (excepts `SELECT... FOR UPDATE`), for example:

```go
// `User` Resolver 示例
DB.Table("users").Rows() // replicas `db5`
DB.Model(&User{}).Find(&AdvancedUser{}) // replicas `db5`
DB.Exec("update users set name = ?", "jinzhu") // sources `db1`
DB.Raw("select name from users").Row().Scan(&name) // replicas `db5`
DB.Create(&user) // sources `db1`
DB.Delete(&User{}, "name = ?", "jinzhu") // sources `db1`
DB.Table("users").Update("name", "jinzhu") // sources `db1`

// 全局 Resolver 示例
DB.Find(&Pet{}) // replicas `db3`/`db4`
DB.Save(&Pet{}) // sources `db2`

// Orders Resolver 示例
DB.Find(&Order{}) // replicas `db8`
DB.Table("orders").Find(&Report{}) // replicas `db8`
```

## 读写分离

Read/Write splitting with DBResolver based on the current used [GORM callbacks](https://gorm.io/docs/write_plugins.html).

对于 `Query`、`Row` callback，如果手动指定为 `Write` 模式，此时会使用 `sources`，否则使用 `replicas`。 对于 `Raw` callback，如果 SQL 是以 `SELECT` 开头，语句会被认为是只读的，会使用 `replicas`，否则会使用 `sources`。

## 手动切换连接

```go
// 使用 Write 模式：从 sources db `db1` 读取 user
DB.Clauses(dbresolver.Write).First(&user)

// 指定 Resolver：从 `secondary` 的 replicas db `db8` 读取 user
DB.Clauses(dbresolver.Use("secondary")).First(&user)

// 指定 Resolver 和 Write 模式：从 `secondary` 的 sources db `db6` 或 `db7` 读取 user
DB.Clauses(dbresolver.Use("secondary"), dbresolver.Write).First(&user)
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
DB.Use(
  dbresolver.Register(dbresolver.Config{ /* xxx */ }).
  SetConnMaxIdleTime(time.Hour).
  SetConnMaxLifetime(24 * time.Hour).
  SetMaxIdleConns(100).
  SetMaxOpenConns(200)
)
```
