---
title: GORM 指南
layout: page
---

一个致力于对开发者友好的优秀 Golang ORM 库。

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
* 用于类型安全查询和操作的泛型 API
* 可扩展且灵活的插件 API：数据库解析器（支持多数据库、读写分离）或 Prometheus 集成等
* 每个特性都经过了测试的重重考验
* 开发者友好

## 安装

```sh
go get -u gorm.io/gorm
go get -u gorm.io/driver/sqlite
```

## 快速入门

### 泛型 API (>= v1.30.0)

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
    panic("连接数据库失败")
  }

  ctx := context.Background()

  // 自动建表
  db.AutoMigrate(&Product{})

  // 创建
  err = gorm.G[Product](db).Create(ctx, &Product{Code: "D42", Price: 100})

  // 查询
  product, err := gorm.G[Product](db).Where("id = ?", 1).First(ctx) // 查找对应主键的产品
  products, err := gorm.G[Product](db).Where("code = ?", "D42").Find(ctx) // 查找 code 为 D42 的所有产品

  // 更新 - 将产品价格更新为 200
  err = gorm.G[Product](db).Where("id = ?", product.ID).Update(ctx, "Price", 200)
  // 更新 - 更新多个字段
  err = gorm.G[Product](db).Where("id = ?", product.ID).Updates(ctx, Product{Code: "D42", Price: 100})

  // 删除 - 删除产品
  err = gorm.G[Product](db).Where("id = ?", product.ID).Delete(ctx)
}
```

### 传统 API

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
    panic("连接数据库失败")
  }

  // 自动建表
  db.AutoMigrate(&Product{})

  // 创建
  db.Create(&Product{Code: "D42", Price: 100})

  // 查询
  var product Product
  db.First(&product, 1) // 查找对应主键的产品
  db.First(&product, "code = ?", "D42") // 查找 code 为 D42 的所有产品

  // 更新 - 将产品价格更新为 200
  db.Model(&product).Update("Price", 200)
  // 更新 - 更新多个字段
db.Model(&product).Updates(Product{Price: 200, Code: "F42"}) // 仅更新非零字段
  db.Model(&product).Updates(map[string]interface{}{"Price": 200, "Code": "F42"})

  // 删除 - 删除产品
  db.Delete(&product, 1)
}
```
