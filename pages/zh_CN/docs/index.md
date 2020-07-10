---
title: GORM 指南
layout: page
---

The fantastic ORM library for Golang aims to be developer friendly.

## 特性

* 全功能 ORM
* 关联 (Has One、Has Many、Belongs To、Many To Many、多态、单表继承)
* Create、Save、Update、Delete、Find 前/后的勾子
* Eager loading with `Preload`, `Joins`
* Transactions, Nested Transactions, Save Point, RollbackTo to Saved Point
* Context, Prepared Statment Mode, DryRun Mode
* Batch Insert, FindInBatches, Find To Map
* SQL Builder, Upsert, Locking, Optimizer/Index/Comment Hints
* Composite Primary Key
* Auto Migrations
* Logger
* Extendable, write Plugins based on GORM callbacks
* Every feature comes with tests
* Developer Friendly

## 安装

```sh
go get -u gorm.io/gorm
```

## Quick Start

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
