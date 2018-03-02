---
title: GORM Guides
layout: page
---
Perpustakaan ORM yang fantastis untuk Golang, bertujuan untuk menjadi pengembang yang ramah.

## Overview

* Full-Featured ORM (almost)
* Asosiasi (Memiliki Satu, Memiliki Banyak, Milik Banyak, Banyaknya Polimorfisme)
* Hooks (Before/After Create/Save/Update/Delete/Find)
* Preloading (eager loading)
* Transaksi
* Kunci Utama Komposit
* SQL Builder
* Auto Migrations
* Logger
* Extendable, write Plugins based on GORM callbacks
* Every feature comes with tests
* Developer Friendly

## Install

```sh
go get -u github.com/jinzhu/gorm
```

## Quick Start

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