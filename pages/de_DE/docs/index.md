---
title: GORM Leitfaden
layout: page
---

Die fantastische, entwicklerfreundlich ORM-Bibliothek für Golang

## Übersicht

* Voll ausgestattetes ORM (fast)
* Assoziationen (Has One, Has Many, Belongs To, Many To Many, Polymorphie)
* Hooks (Vorher/Nachher Erstellen/Speichern/ Aktualisieren/Löschen/Suchen)
* Preloading (Eager Loading)
* Transaktionen
* Zusammengesetzte Primärschlüssel
* SQL-Abfragegenerator
* Auto-Migrationen
* Logger
* Erweiterbar - schreibe Plugins basierend auf GORM's Rückrufen
* Alle Features sind getestet
* Entwickler-freundlich

## Installation

```sh
go get -u github.com/jinzhu/gorm
```

## Schnelleinstieg

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

  // Migriere das Schema
  db.AutoMigrate(&Product{})

  // Erstellen
  db.Create(&Product{Code: "L1212", Price: 1000})

  // Lesen
  var product Product
  db.First(&product, 1) // find product with id 1
  db.First(&product, "code = ?", "L1212") // find product with code l1212

  // Aktualisieren - aktualisiere den Produktpreis zu 2000
  db.Model(&product).Update("Price", 2000)

  // Löschen - lösche das Produkt
  db.Delete(&product)
}
```