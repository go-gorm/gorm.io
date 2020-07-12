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
* Context、プリペアドステートメント、ドライラン
* バッチインサート、FindInBatches,、Find To Map
* SQLビルダー、Upsert、 Locking、Optimizer/Index/Commentヒント
* 複合主キー
* オートマイグレーション
* ロガー
* GORMコールバックベースのプラグインを記述することで拡張可能
* すべての機能に付属するテストコード
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

  // Create - 作成
  db.Create(&Product{Code: "D42", Price: 100})

  // Read - 取得
  var product Product
  db.First(&product, 1) // 主キーでproductを取得する
  db.First(&product, "code = ?", "D42") // codeがD42であるproductを取得する

  // Update - productのPriceを200に更新
  db.Model(&product).Update("Price", 200)
  // Update - 複数のフィールドを更新
  db.Model(&product).Updates(Product{Price: 200, Code: "F42"}) // 非ゼロ値フィールドのみ
  db.Model(&product).Updates(map[string]interface{}{"Price": 200, "Code": "F42"})

  // Delete - productを削除
  db.Delete(&product, 1)
}
```
