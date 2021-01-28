---
title: Guides GORM
layout: page
---

La fantastique bibliothèque ORM pour Golang, conviviale pour les développeurs.

## Vue d'ensemble

* ORM complet
* Associations (A un, A plusieurs, Appartient à, Beaucoup à plusieurs, Polymorphisme, Héritage à table unique)
* Hooks (Before/After Create/Save/Update/Delete/Find)
* Eager loading with `Preload`, `Joins`
* Transactions, Nested Transactions, Save Point, RollbackTo to Saved Point
* Context, Prepared Statement Mode, DryRun Mode
* Batch Insert, FindInBatches, Find/Create with Map, CRUD with SQL Expr and Context Valuer
* SQL Builder, Upsert, Locking, Optimizer/Index/Comment Hints, Named Argument, SubQuery
* Composite Primary Key, Indexes, Constraints
* Migrations automatiques
* Logger
* Extendable, flexible plugin API: Database Resolver (Multiple Databases, Read/Write Splitting) / Prometheus...
* Chaque fonctionnalité est livrée avec des tests
* Conviviale pour les développeurs

## Installation

```sh
go get -u gorm.io/gorm
go get -u gorm.io/driver/sqlite
```

## Démarrage rapide

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
