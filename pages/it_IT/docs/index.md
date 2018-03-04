---
title: Guida GORM
layout: page
---
La fantastica libreria ORM per Goland, mira ad essere di semplice utilizzo per gli sviluppatori.

## Panoramica

* Full-optional ORM (quasi)
* Associazioni (a uno, a molte, appartiene a, molti a molti, polimorfismi)
* Agganci (Prima/Dopo Crea/Salva/Aggiorna/Cancella/Trova)
* Pre-caricamento (caricamento rapido)
* Transazioni
* Chiave primaria composita
* SQL Builder
* Migrazione automatica
* Logger
* Estendibile, crea dei Plugins basati sui callbacks di GORM
* Ogni funzione viene prima testata
* Facile da utilizzare

## Per installare

```sh
go get -u github.com/jinzhu/gorm
```

## Guida Rapida

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