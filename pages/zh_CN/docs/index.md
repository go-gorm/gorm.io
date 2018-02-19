---
title: GORM 指南
layout: page
---
The fantastic ORM library for Golang, aims to be developer friendly.

## 概览

* 全功能 ORM (无限接近)
* 关联（包含一个，包含多个，属于，多对多，多态）
* 钩子 (在创建/保存/更新/删除/查找之前或之后)
* 预加载
* 事务
* 复合主键
* SQL 生成器
* 数据库自动迁移
* 自定义日志
* 可扩展性, 可基于 GORM 回调编写插件
* 所有功能都被测试覆盖
* 开发者友好

## 安装

```sh
go get -u github.com/jinzhu/gorm
```

## 快速入门

```go
package main

import (
  "github.com/jinzhu/gorm"
  _ "github.com/jinzhu/gorm/dialects/sqlite"
)

type Product struct {
  gorm.Model
  Code string
  Price uint
}

func main() {
  db, err := gorm.Open("sqlite3", "test.db")
  if err != nil {
    panic("failed to connect database")
  }
  defer db.Close()

  // Migrate the schema
  db.AutoMigrate(&Product{})

  // Create
  db.Create(&Product{Code: "L1212", Price: 1000})

  // Read
  var product Product
  db.First(&product, 1) // find product with id 1
  db.First(&product, "code = ?", "L1212") // find product with code l1212

  // Update - update product's price to 2000
  db.Model(&product).Update("Price", 2000)

  // Delete - delete product
  db.Delete(&product)
}
```