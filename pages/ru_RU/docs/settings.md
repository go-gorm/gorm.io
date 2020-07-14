---
title: Настройки
layout: страница
---

GORM предоставляет методы `Set`, `Get`, `InstanceSet`, `InstanceGet`, которые позволяют пользователям передавать значения в [хуки](hooks.html) или другие методы

GORM использует это для некоторых функций, таких как передача создания параметров таблицы при миграции.

```go
// Добавляем суффикс таблицы при создании таблиц
db.Set("gorm:table_options", "ENGINE=InnoDB").AutoMigrate(&User{})
```

## Set / Get

Используйте `Set` / `Get` для передачи параметров в методы хуков, например:

```go
type User struct {
  gorm.Model
  CreditCard CreditCard
  // ...
}

func (u *User) BeforeCreate(tx *gorm.DB) error {
  myValue, ok := tx.Get("my_value")
  // ok => true
  // myValue => 123
}

type CreditCard struct {
  gorm.Model
  // ...
}

func (card *CreditCard) BeforeCreate(tx *gorm.DB) error {
  myValue, ok := tx.Get("my_value")
  // ok => true
  // myValue => 123
}

myValue := 123
db.Set("my_value", myValue).Create(&User{})
```


## InstanceSet / InstanceGet

Используйте `InstanceSet` / `InstanceGet` чтобы передать настройки текущему `*Statement` методам хуков, например:

```go
type User struct {
  gorm.Model
  CreditCard CreditCard
  // ...
}

func (u *User) BeforeCreate(tx *gorm.DB) error {
  myValue, ok := tx.InstanceGet("my_value")
  // ok => true
  // myValue => 123
}

type CreditCard struct {
  gorm.Model
  // ...
}

// При создании связей, GORM создает новый `*Statement`, поэтому не может читать настройки других экземпляров
func (card *CreditCard) BeforeCreate(tx *gorm.DB) error {
  myValue, ok := tx.InstanceGet("my_value")
  // ok => false
  // myValue => nil
}

myValue := 123
db.InstanceSet("my_value", myValue).Create(&User{})
```
