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
* Generics API for type-safe queries and operations
* Extendable, flexible plugin API: Database Resolver (multiple databases, read/write splitting) / Prometheus...
* Chaque fonctionnalité est livrée avec des tests
* Conviviale pour les développeurs

## Installation

```sh
go get -u gorm.io/gorm
go get -u gorm.io/driver/sqlite
```

## Démarrage rapide

### Generics API (>= v1.30.0)

```go
package main

import (
  "context"
  "gorm.io/driver/sqlite"
  "gorm.io/gorm"
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

  ctx := context.Background()

  // Migrate the schema
  db.AutoMigrate(&Product{})

  // Create
  err = gorm.G[Product](db).Create(ctx, &Product{Code: "D42", Price: 100})

  // Read
  product, err := gorm.G[Product](db).Where("id = ?", 1).First(ctx) // find product with integer primary key
  products, err := gorm.G[Product](db).Where("code = ?", "D42").Find(ctx) // find product with code D42

  // Update - update product's price to 200
  err = gorm.G[Product](db).Where("id = ?", product.ID).Update(ctx, "Price", 200)
  // Update - update multiple fields
  err = gorm.G[Product](db).Where("id = ?", product.ID).Updates(ctx, map[string]interface{}{"Price": 200, "Code": "F42"})

  // Delete - delete product
  err = gorm.G[Product](db).Where("id = ?", product.ID).Delete(ctx)
}
```

### Traditional API

```go
package main

import (
  "gorm.io/driver/sqlite"
  "gorm.io/gorm"
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
