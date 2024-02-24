---
title: GORM Anleitungen
layout: page
---

Die fantastische ORM Bibliothek für Golang, stets auf Entwickler-Freundlichkeit aus.

## Überblick

* Voll-funktionales ORM
* Associations (Has One, Has Many, Belongs To, Many To Many, Polymorphism, Single-table inheritance)
* Hooks (Before/After Create/Save/Update/Delete/Find)
* Eager loading with `Preload`, `Joins`
* Transactions, Nested Transactions, Save Point, RollbackTo to Saved Point
* Context, Prepared Statement Mode, DryRun Mode
* Batch Insert, FindInBatches, Find/Create with Map, CRUD with SQL Expr and Context Valuer
* SQL Builder, Upsert, Locking, Optimizer/Index/Comment Hints, Named Argument, SubQuery
* Zusammen gesetzte Primärschlüssel, Indizes, Einschränkungen
* Automatische Datenbank Migrationen
* Logger
* Extendable, flexible plugin API: Database Resolver (Multiple Databases, Read/Write Splitting) / Prometheus...
* Jedes Feature wurde getestet
* Entwickler-freundlich

## Installation

```sh
go get -u gorm.io/gorm
go get -u gorm.io/driver/sqlite
```

## Schnelleinstieg

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
    panic("Fehler bei der Verbindung zur Datenbank")
  }

  // Migrieren des Schemas
  db.AutoMigrate(&Product{})

  // Erstellen
  db.Create(&Product{Code: "D42", Price: 100})

  // Auslesen
  var product Product
  db.First(&product, 1) // find product with integer primary key
  db.First(&product, "code = ?", "D42") // find product with code D42

  // Bearbeiten - ändern des Produkt-Preises auf 200
  db.Model(&product).Update("Price", 200)
  // Bearbeiten - ändern mehrerer Felder
  db.Model(&product).Updates(Product{Price: 200, Code: "F42"}) // non-zero fields
  db.Model(&product).Updates(map[string]interface{}{"Price": 200, "Code": "F42"})

  // Löschen - Produkt löschen
  db.Delete(&product, 1)
}
```
