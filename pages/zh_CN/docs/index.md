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
* 事务、嵌套事务、Save Point、回滚至 Save Point
* Context、Prepared Statment 模式、DryRun 模式
* Batch Insert, FindInBatches, Find To Map
* SQL Builder, Upsert, Locking, Optimizer/Index/Comment Hints
* 复合主键
* 自动迁移
* 自定义日志
* 可扩展性, 可基于 GORM callback 编写插件
* 所有特性都通过了测试
* 开发者友好

## 安装

```sh
go get -u gorm.io/gorm
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
  defer db.Close()

  // 自动迁移 schema
  db.AutoMigrate(&Product{})

  // 创建
  db.Create(&Product{Code: "D42", Price: 100})

  // 查询首条记录
  var product Product
  db.First(&product, 1) // 查询整型主键值为 1 的 product
  db.First(&product, "code = ?", "D42") // 查询 code 为 D42 的 product

  // Update - 将 product 的 Price 更新为 200
  db.Model(&product).Update("Price", 200)
  // Update - update multiple fields
  db.Model(&product).Updates(Product{Price: 200, Code: "F42"}) // 仅更新非零值字段
  db.Model(&product).Updates(map[string]interface{}{"Price": 200, "Code": "F42"})

  // Delete - 删除 product
  db.Delete(&product, 1)
}
```
