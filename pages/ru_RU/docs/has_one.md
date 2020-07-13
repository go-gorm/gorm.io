---
title: Has One (имеет одну)
layout: страница
---

## Has One (имеет одну)

Связь `has one` устанавливает связь с другой моделью, но с несколько разными семантиками (и последствиями). Эта ассоциация указывает, что каждый экземпляр модели содержит или обладает одной другой моделью.

Например, если ваше приложение включает пользователей и кредитные карты, и каждый пользователь может иметь только одну кредитную карту.

```go
// User имеет одну CreditCard, CreditCardID это внешний ключ
type User struct {
  gorm.Model
  CreditCard CreditCard
}

type CreditCard struct {
  gorm.Model
  Number string
  UserID uint
}
```

## Переопределить внешний ключ

Для связи `has one`, должен существовать внешний ключ, владелец сохранит первичный ключ модели принадлежащий ей в этом поле.

Название поля, как правило, генерируется при помощи типа модели `has one` плюс `первичный ключ`, для приведенного выше примера: `UserID`.

Когда вы даете пользователю кредитную карту, он сохранит `ID` пользователя в поле `UserID`.

Если вы хотите использовать другое поле для сохранения связей, вы можете изменить его при помощи тега `foreignKey`, например:

```go
type User struct {
  gorm.Model
  CreditCard CreditCard `gorm:"foreignKey:UserName"`
  // использовать UserName как внешний ключ
}

type CreditCard struct {
  gorm.Model
  Number   string
  UserName string
}
```

## Переопределить связи

By default, the owned entity will save the `has one` model's primary key into a foreign key, you could change to save another field, like using `Name` for the below example.

You are able to change it with tag `references`, e.g:

```go
type User struct {
  gorm.Model
  Name       string     `sql:"index"`
  CreditCard CreditCard `gorm:"foreignkey:UserName;references:name"`
}

type CreditCard struct {
  gorm.Model
  Number   string
  UserName string
}
```

## Polymorphism Association

GORM supports polymorphism association for `has one` and `has many`, it will save owned entity's table name into polymorphic type's field, primary key into the polymorphic field, primary key value into the polymorphic field

```go
type Cat struct {
  ID    int
  Name  string
  Toy   Toy `gorm:"polymorphic:Owner;"`
}

type Dog struct {
  ID   int
  Name string
  Toy  Toy `gorm:"polymorphic:Owner;"`
}

type Toy struct {
  ID        int
  Name      string
  OwnerID   int
  OwnerType string
}

db.Create(&Dog{Name: "dog1", Toy: Toy{Name: "toy1"}})
// INSERT INTO `dogs` (`name`) VALUES ("dog1")
// INSERT INTO `toys` (`name`,`owner_id`,`owner_type`) VALUES ("toy1","1","dogs")
```

You can change the polymorphic type value with tag `polymorphicValue`, for example:

```go
type Dog struct {
  ID   int
  Name string
  Toy  Toy `gorm:"polymorphic:Owner;polymorphicValue:master"`
}

type Toy struct {
  ID        int
  Name      string
  OwnerID   int
  OwnerType string
}

db.Create(&Dog{Name: "dog1", Toy: Toy{Name: "toy1"}})
// INSERT INTO `dogs` (`name`) VALUES ("dog1")
// INSERT INTO `toys` (`name`,`owner_id`,`owner_type`) VALUES ("toy1","1","master")
```

## CRUD with Has One

Please checkout [Association Mode](associations.html#Association-Mode) for working with `has one` relations

## Eager Loading

GORM allows eager loading `has one` associations with `Preload` or `Joins`, refer [Preloading (Eager loading)](preload.html) for details

## Self-Referential Has One

```go
type User struct {
  gorm.Model
  Name      string
  ManagerID *uint
  Manager   *User
}
```

## FOREIGN KEY Constraints

You can setup `OnUpdate`, `OnDelete` constraints with tag `constraint`, for example:

```go
type User struct {
  gorm.Model
  CreditCard CreditCard `gorm:"constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`
}

type CreditCard struct {
  gorm.Model
  Number string
  UserID uint
}
```
