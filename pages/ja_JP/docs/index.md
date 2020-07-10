---
title: GORMガイド
layout: page
---

Golangのための素晴らしいORMライブラリは、開発者に優しいことを目指しています。

## 概略

* フル機能ORM
* アソシエーションに対応 (Has One, Has Many, Belongs To, Many To Many, Polymorphism, Single-table inheritance)
* さまざまなフック (Before/After Create/Save/Update/Delete/Find)
* Eager loading with `Preload`, `Joins`
* Transactions, Nested Transactions, Save Point, RollbackTo to Saved Point
* Context、プリペアドステートメント、ドライラン
* バッチインサート、FindInBatches,、Find To Map
* SQL Builder, Upsert, Locking, Optimizer/Index/Comment Hints, NamedArg
* 複合主キー
* 自動データベースマイグレーション
* ロガー
* 拡張可能。GORMコールバックに基づいてプラグインを書くことができる
* すべての機能にはテストが付属しています
* デベロッパーフレンドリー

## インストール

```sh
go get -u gorm.io/gorm
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
  defer db.Close()

  // スキーマのマイグレーション
  db.AutoMigrate(&Product{})

  // Create
  db.Create(&Product{Code: "D42", Price: 100})

  // Read
  var product Product
  db.First(&product, 1) // find product with integer primary key
  db.First(&product, "code = ?", "D42") // find product with code D42

  // Update - productのPriceを200に更新
  db.Model(&product).Update("Price", 200)
  // Update - 複数のフィールドを更新
  db.Model(&product).Updates(Product{Price: 200, Code: "F42"}) // non-zero fields
  db.Model(&product).Updates(map[string]interface{}{"Price": 200, "Code": "F42"})

  // Delete - productを削除
  db.Delete(&product, 1)
}
```
