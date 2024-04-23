---
title: Sharding
layout: page
---

Sharding 是一个高性能的 Gorm 分表中间件。它基于 Conn 层做 SQL 拦截、AST 解析、分表路由、自增主键填充，带来的额外开销极小。对开发者友好、透明，使用上与普通 SQL、Gorm 查询无差别，只需要额外注意一下分表键条件。 为您提供高性能的数据库访问。

https://github.com/go-gorm/sharding

## 功能特点

- 非侵入式设计， 加载插件，指定配置，既可实现分表。
- 轻快， 非基于网络层的中间件，像 Go 一样快
- 支持多种数据库。 PostgreSQL 已通过测试，MySQL 和 SQLite 也在路上。
- 多种主键生成方式支持（Snowflake, PostgreSQL Sequence, 以及自定义支持）Snowflake 支持从主键中确定分表键。

## 使用说明

配置 Sharding 中间件，为需要分表的业务表定义他们分表的规则。 See [Godoc](https://pkg.go.dev/gorm.io/sharding) for config details.

```go
import (
    "fmt"

    "gorm.io/driver/postgres"
    "gorm.io/gorm"
    "gorm.io/sharding"
)

dsn := "postgres://localhost:5432/sharding-db?sslmode=disable"
db, err := gorm.Open(postgres.New(postgres.Config{DSN: dsn}))

db.Use(sharding.Register(sharding.Config{
    ShardingKey:         "user_id",
    NumberOfShards:      64,
    PrimaryKeyGenerator: sharding.PKSnowflake,
}, "orders").Register(sharding.Config{
    ShardingKey:         "user_id",
    NumberOfShards:      256,
    PrimaryKeyGenerator: sharding.PKSnowflake,
    // This case for show up give notifications, audit_logs table use same sharding rule.
}, Notification{}, AuditLog{}))
```

依然保持原来的方式使用 db 来查询数据库。 你只需要注意在 CURD 动作的时候，`明确知道 Sharding Key` 对应的分表，查询条件带 Sharding Key，以确保 Sharding 能理解数据需要对应到哪一个子表。

```go
// GORM 创建示例，这会插入到 orders_02 表
db.Create(&Order{UserID: 2})
// sql: INSERT INTO orders_2 ...

// 原生 SQL 插入示例，这会插入到 orders_03 表
db.Exec("INSERT INTO orders(user_id) VALUES(?)", int64(3))

// 这会抛出 ErrMissingShardingKey 错误，因此此处没有提供 sharding key
db.Create(&Order{Amount: 10, ProductID: 100})
fmt.Println(err)

// Find 方法，这会检索 order_02 表
var orders []Order
db.Model(&Order{}).Where("user_id", int64(2)).Find(&orders)
fmt.Printf("%#v\n", orders)

// 原生 SQL 也是支持的
db.Raw("SELECT * FROM orders WHERE user_id = ?", int64(3)).Scan(&orders)
fmt.Printf("%#v\n", orders)

// 这会抛出 ErrMissingShardingKey 错误，因为 WHERE 条件没有包含 sharding key
err = db.Model(&Order{}).Where("product_id", "1").Find(&orders).Error
fmt.Println(err)

// Update 和 Delete 方法与创建、查询类似
db.Exec("UPDATE orders SET product_id = ? WHERE user_id = ?", 2, int64(3))
err = db.Exec("DELETE FROM orders WHERE product_id = 3").Error
fmt.Println(err) // ErrMissingShardingKey
```

完整示例演示 [Example](https://github.com/go-gorm/sharding/tree/main/examples)。
