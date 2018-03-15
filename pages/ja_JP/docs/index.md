---
title: GORM ガイド
layout: page
---
The fantastic ORM library for Golang, aims to be developer friendly.

## 概要

* （ほぼ）フル機能を備えたORM
* アソシエーション(Has One, Has Many, Belongs To, Many To Many, Polymorphism)
* フック(Before/After Create/Save/Update/Delete/Find)
* プリローディング(eager loading)
* トランザクション
* 複合主キー
* SQLビルダー
* オートマイグレーション
* ロガー
* GORMのコールバックベースのプラグイン記述で拡張可能
* 各機能ごとに付属するテストコード
* デベロッパーフレンドリー

## インストール

```sh
go get -u github.com/jinzhu/gorm
```

## クイックスタート

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