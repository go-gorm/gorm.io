---
title: Guías de GORM
layout: página
---
La fantástica biblioteca ORM de Golang, aspira a ser desarrollador amigable.

## Información General

* Características completas ORM (al menos)
* Asociaciones (Tiene uno, Tiene algunos, pertenece a, muchos a muchos, polimorfismo)
* Ganchos (antes/después Crear/guardar/actualizar/eliminar/buscar)
* Precarga (carga impaciente)
* Transacciones
* Clave primaria compuesta
* Constructor SQL
* Migraciones automaticas
* Registrador
* Extensible, escribir Plugins basado en callbacks GORM
* Cada característica viene con pruebas
* Desarrollador amigable

## Instalar

```sh
go get -u github.com/jinzhu/gorm
```

## Inicio Rápido

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