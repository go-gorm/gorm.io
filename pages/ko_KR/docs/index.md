---
title: GORM 가이드
layout: page
---

개발자 친화적인 환상적인 Go언어용 ORM라이브러리

## 개요

* (거의) 모든 기능을 갖춘 ORM
* Associations (Has One, Has Many, Belongs To, Many To Many, Polymorphism)
* Hooks (Before/After Create/Save/Update/Delete/Find)
* Preloading (eager loading)
* Transactions
* Composite Primary Key
* SQL 빌더
* 자동 마이그레이션
* Logger
* Extendable, write Plugins based on GORM callbacks
* 모든 기능에 테스트 코드가 제공됨
* 개발자 친화적

## 인스톨

```sh
go get -u github.com/jinzhu/gorm
```

## 빠른 시작

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