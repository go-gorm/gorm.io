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
* Расширяемый, пишите плагины на основе методов GORM
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
  defer db.Close()

  // Миграция
  db.AutoMigrate(&Product{})

  // Создание
  db.Create(&Product{Code: "D42", Price: 100})

  // Чтение
  var product Product
  db.First(&product, 1) // найти товар с целочисленным первичным ключем
  db.First(&product, "code = ?", "D42") // найти товар с кодом D42

  // Обновление - заменить цену товара на 200
  db.Model(&product).Update("Price", 200)
  // Обновление - изменение нескольких полей
  db.Model(&product).Updates(Product{Price: 200, Code: "F42"}) // не нулевые поля
  db.Model(&product).Updates(map[string]interface{}{"Price": 200, "Code": "F42"})

  // Удаление - удалить товар
  db.Delete(&product, 1)
}
```
