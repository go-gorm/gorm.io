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
* 事务

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

## 自动切换连接

DBResolver 会根据工作表、struct 自动切换连接

对于原生 SQL，DBResolver 会从 SQL 中提取表名以匹配 Resolver，除非 SQL 开头为 `SELECT`（select for update 除外），否则 DBResolver 总是会使用 `sources` ，例如：

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

## 读写分离

DBResolver 的读写分离目前是基于 [GORM callback](https://gorm.io/docs/write_plugins.html) 实现的。

对于 `Query`、`Row` callback，如果手动指定为 `Write` 模式，此时会使用 `sources`，否则使用 `replicas`。 对于 `Raw` callback，如果 SQL 是以 `SELECT` 开头，语句会被认为是只读的，会使用 `replicas`，否则会使用 `sources`。

## 手动切换连接

```go
// 使用 Write 模式：从 sources db `db1` 读取 user
db.Clauses(dbresolver.Write).First(&user)

// 指定 Resolver：从 `secondary` 的 replicas db `db8` 读取 user
db.Clauses(dbresolver.Use("secondary")).First(&user)

// 指定 Resolver 和 Write 模式：从 `secondary` 的 sources db `db6` 或 `db7` 读取 user
db.Clauses(dbresolver.Use("secondary"), dbresolver.Write).First(&user)
```

## 事务

使用事务时，DBResolver 也会保持使用一个事务，且不会根据配置切换 sources/replicas 连接

但您可以在事务开始之前指定使用哪个数据库，例如：

```go
// 通过默认 replicas db 开始事务
tx := DB.Clauses(dbresolver.Read).Begin()

// 通过默认 sources db 开始事务
tx := DB.Clauses(dbresolver.Write).Begin()

// 通过 `secondary` 的 sources db 开始事务
tx := DB.Clauses(dbresolver.Use("secondary"), dbresolver.Write).Begin()
```

## 负载均衡

GORM 支持基于策略的 sources/replicas 负载均衡，自定义策略应该是一个实现了以下接口的 struct：

```go
type Policy interface {
    Resolve([]gorm.ConnPool) gorm.ConnPool
}
```

当前只实现了一个 `RandomPolicy` 策略，如果没有指定其它策略，它就是默认策略。

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
