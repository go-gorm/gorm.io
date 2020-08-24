---
title: GORM 指南
layout: page
---

The fantastic ORM library for Golang aims to be developer friendly.

## 特性

* 全功能 ORM
* 关联 (Has One、Has Many、Belongs To、Many To Many、多态、单表继承)
* Create、Save、Update、Delete、Find 前/后的勾子
* 基于 `Preload`、`Joins` 的预加载
* 事务、嵌套事务、保存点、回滚至保存点
* Context、Prepared Statment 模式、DryRun 模式
* 批量插入、FindInBatches、查询至 Map
* SQL Builder, Upsert, Locking, Optimizer/Index/Comment Hints
* 复合主键
* 自动迁移
* 自定义 Logger
* Extendable, flexible plugin API: Database Resolver (Multiple Databases, Read/Write Splitting) / Prometheus...
* 所有特性都通过了测试
* 开发者友好

## 安装

```sh
go get -u gorm.io/gorm
go get -u gorm.io/driver/sqlite
```

## 快速入门

```go
package main

import (
  "gorm.io/gorm"
  "gorm.io/driver/sqlite"
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

  // 迁移 schema
  db.AutoMigrate(&Product{})

  // Create
  db.Create(&Product{Code: "D42", Price: 100})

  // Read
  var product Product
  db.First(&product, 1) // 根据整形主键查找
  db.First(&product, "code = ?", "D42") // 查找 code 字段值为 D42 的记录

  // Update - 将 product 的 price 更新为 200
  db.Model(&product).Update("Price", 200)
  // Update - 更新多个字段
  db.Model(&product).Updates(Product{Price: 200, Code: "F42"}) // 仅更新非零值字段
  db.Model(&product).Updates(map[string]interface{}{"Price": 200, "Code": "F42"})

  // Delete - 删除 product
  db.Delete(&product, 1)
}
```
