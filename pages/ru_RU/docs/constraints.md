---
title: Ограничения
layout: страница
---

GORM позволяет создавать ограничения базы данных с тегом, ограничения будут создаваться, при [авто миграции (AutoMigrate) или создании таблицы (CreateTable) с GORM](migration.html)

## Ограничение CHECK

Создадим CHECK ограничения при помощи тега `check`

```go
type UserIndex struct {
    Name  string `gorm:"check:name_checker,name <> 'jinzhu'"`
    Name2 string `gorm:"check:name <> 'jinzhu'"`
    Name3 string `gorm:"check:,name <> 'jinzhu'"`
}
```

## Ограничение индекса

Смотрите [Индексы базы данных](indexes.html)

## Ограничения внешнего ключа

GORM создаст ограничения внешних ключей для ассоциаций, вы можете отключить эту функцию во время инициализации:

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DisableForeignKeyConstraintWhenMigrating: true,
})
```

GORM allows you setup FOREIGN KEY constraints's `OnDelete`, `OnUpdate` option with tag `constraint`, for example:

```go
type User struct {
  gorm.Model
  CompanyID  int
  Company    Company    `gorm:"constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`
  CreditCard CreditCard `gorm:"constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`
}

type CreditCard struct {
  gorm.Model
  Number string
  UserID uint
}

type Company struct {
  ID   int
  Name string
}
```
