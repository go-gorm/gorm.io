---
title: GORM 指南
layout: page
---

The fantastic ORM library for Golang aims to be developer friendly.

## 特性

* 全功能 ORM
* 关联 (Has One，Has Many，Belongs To，Many To Many，多态，单表继承)
* Create，Save，Update，Delete，Find 中钩子方法
* 支持 `Preload`、`Joins` 的预加载
* 事务，嵌套事务，Save Point，Rollback To Saved Point
* Context、预编译模式、DryRun 模式
* 批量插入，FindInBatches，Find/Create with Map，使用 SQL 表达式、Context Valuer 进行 CRUD
* SQL 构建器，Upsert，数据库锁，Optimizer/Index/Comment Hint，命名参数，子查询
* 复合主键，索引，约束
* Auto Migration
* 自定义 Logger
* Generics API for type-safe queries and operations
* Extendable, flexible plugin API: Database Resolver (multiple databases, read/write splitting) / Prometheus...
* 每个特性都经过了测试的重重考验
* 开发者友好

## 安装

```sh
go get -u gorm.io/gorm
go get -u gorm.io/driver/sqlite
```

## 快速入门

### Generics API (>= v1.30.0)

```go
package main

import (
  "context"
  "gorm.io/driver/sqlite"
  "gorm.io/gorm"
)

type Product struct {
  gorm.Model
  Code  string
  Price uint
}

func main() {
  db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
  if err != nil {
    panic("failed to connect database")
  }

  ctx := context.Background()

  // Migrate the schema
  db.AutoMigrate(&Product{})

  // Create
  err = gorm.G[Product](db).Create(ctx, &Product{Code: "D42", Price: 100})

  // Read
  product, err := gorm.G[Product](db).Where("id = ?", 1).First(ctx) // find product with integer primary key
  products, err := gorm.G[Product](db).Where("code = ?", "D42").Find(ctx) // find product with code D42

  // Update - update product's price to 200
  err = gorm.G[Product](db).Where("id = ?", product.ID).Update(ctx, "Price", 200)
  // Update - update multiple fields
  err = gorm.G[Product](db).Where("id = ?", product.ID).Updates(ctx, map[string]interface{}{"Price": 200, "Code": "F42"})

  // Delete - delete product
  err = gorm.G[Product](db).Where("id = ?", product.ID).Delete(ctx)
}
```

### Traditional API

```go
package main

import (
  "gorm.io/driver/sqlite"
  "gorm.io/gorm"
)

type Product struct {
  gorm.Model
  Code  string
  Price uint
}

func main() {
  db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
  if err != nil {
    panic("failed to connect database")
  }

  // Migrate the schema
  db.AutoMigrate(&Product{})

  // Create
  db.Create(&Product{Code: "D42", Price: 100})

  // Read
  var product Product
  db.First(&product, 1) // find product with integer primary key
  db.First(&product, "code = ?", "D42") // find product with code D42

  // Update - update product's price to 200
  db.Model(&product).Update("Price", 200)
  // Update - update multiple fields
  db.Model(&product).Updates(Product{Price: 200, Code: "F42"}) // non-zero fields
  db.Model(&product).Updates(map[string]interface{}{"Price": 200, "Code": "F42"})

  // Delete - delete product
  db.Delete(&product, 1)
}
```
