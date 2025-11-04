---
title: Guia do GORM
layout: page
---

A fantástica biblioteca ORM para Golang, projetada para ser amigável para desenvolvedores.

## Visão Geral

* ORM Completo
* Associações (Has One, Has Many, Belongs To, Many To Many, Poliformismo e Single-table inheritance)
* Hooks (Before/After Create/Save/Update/Delete/Find)
* Pré-carregamento de dados com `Preload`, `Joins`
* Transações, Transações Aninhadas, Save Point, Rollback para Save Point
* Context, Modo Prepared Statement e DryRun
* Batch Insert, FindInBatches, Find/Create com Map, CRUD com SQL Expr e Context Valuer
* SQL Builder, Upsert, Locking, Optimizer/Index/Comment Hints, Named Argument, SubQuery
* Chave Primária Composta, Índices e Constraints
* Migrações automáticas
* Logger
* Generics API for type-safe queries and operations
* Extendable, flexible plugin API: Database Resolver (multiple databases, read/write splitting) / Prometheus...
* Todas as funcionalidades desenvolvidas com testes
* Amigável para Desenvolvedores

## Instalação

```sh
go get -u gorm.io/gorm
go get -u gorm.io/driver/sqlite
```

## Vamos começar!

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
  err = gorm.G[Product](db).Where("id = ?", product.ID).Updates(ctx, Product{Code: "D42", Price: 100})

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
