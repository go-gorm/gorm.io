---
title: GORMガイド
layout: page
---

デベロッパーフレンドリーを目指した、Go言語のORMライブラリです。

## 特徴

* フル機能ORM
* アソシエーション(Has One, Has Many, Belongs To, Many To Many, Polymorphism, Single-table inheritance)
* フック (Before/After Create/Save/Update/Delete/Find)
* `Preload`, `Joins`を使ったイーガーロード
* トランザクション、ネスティング、セーブポイント、セーブポイントへのロールバック
* Context、プリペアードステートメント、DryRunへの対応
* Batch Insert, FindInBatches, マップを使用してのFind/Create, SQL式やContext Valuerを使用したCRUD操作への対応
* SQL Builder、Upsert、ロック、Optimizer/Index/Comment ヒント、名前付き引数、サブクエリの対応
* 複合主キー、インデックス、データベース制約への対応
* オートマイグレーション
* Logger
* 拡張性のある柔軟なプラグインAPI: データベースリゾルバ(複数のデータベース、読み取り/書き込み分割) や Prometheus など
* すべての機能に付属するテストコード
* デベロッパーフレンドリー

## インストール

```sh
go get -u gorm.io/gorm
go get -u gorm.io/driver/sqlite
```

## クイックスタート

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
