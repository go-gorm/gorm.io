---
title: Руководство GORM
layout: страница
---

Фантастически-простой ORM фреймворк, для Golang разработчиков.

## Обзор

* Полнофункциональный ORM (ну почти)
* Связи (Has One, Has Many, Belongs To, Many To Many, Polymorphism)
* Хуки (Before/After Create/Save/Update/Delete/Find)
* Предварительная загрузка (загрузка пробега)
* Транзакции
* Составной первичный ключ
* Конструктор SQL "SQL Builder"
* Автоматические миграции
* Логирование
* Расширяемые функционал плагины, на основе колбеков
* Каждая функция поставляется с тестами
* Дружественная для разработчиков

## Установка

```sh
go get -u github.com/jinzhu/gorm
```

## Быстрый старт

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

  // Миграция схем
  db.AutoMigrate(&Product{})

  // Соаздние
  db.Create(&Product{Code: "L1212", Price: 1000})

  // Чтение
  var product Product
  db.First(&product, 1) // find product with id 1
  db.First(&product, "code = ?", "L1212") // find product with code l1212

  // Правка - обновление цены на 2000
  db.Model(&product).Update("Price", 2000)

  // Удаление - удалить продкут
  db.Delete(&product)
}
```