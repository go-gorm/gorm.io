---
title: Инструкции по GORM
layout: страница
---

Фантастическая библиотека ORM для Golang призвана быть дружественной для разработчиков.

## Обзор

* Полнофункциональный ORM
* Связи (Has One (имеет одну), Has Many (имеет много), Belongs To (принадлежит), Many To Many (многие ко многим), Polymorphism (полиморфизм), Single-table inheritance (одно табличное представление))
* Хуки (До/После Создать/Сохранить/Обновить/Удалить/Найти)
* Нетерпеливая загрузка с помощью `Preload`, `Joins`
* Транзакции, вложенные транзакции, точки сохранения, откат к сохраненной точке
* Контекст, Режим подготовки, Режим DryRun
* Пакетная вставка, найти в пакете, поиск в map
* Конструктор SQL, Upsert(Создать или обновить), Блокировка, Подсказки Оптимизатор/Индексирование/Комментарий, NamedArg
* Композитный первичный ключ
* Автомиграция
* Logger
* Extendable, flexible plugin API: Database Resolver (Read/Write Splitting) / Prometheus...
* Каждая функция поставляется с тестами
* Дружественная для разработчиков

## Установка

```sh
go get -u gorm.io/gorm
```

## Быстрый старт

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
