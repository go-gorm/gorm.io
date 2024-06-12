---
title: Has One (имеет одну)
layout: страница
---

## Has One (имеет одну)

Связь `has one` устанавливает связь с другой моделью, но с несколько разными семантиками (и последствиями). Эта ассоциация указывает, что каждый экземпляр модели содержит или обладает одной другой моделью.

Например, если ваше приложение включает пользователей и кредитные карты, и каждый пользователь может иметь только одну кредитную карту.

### Определение
```go
// User has one CreditCard, UserID is the foreign key
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

### Извлечение
```go
// Retrieve user list with eager loading credit card
func GetAll(db *gorm.DB) ([]User, error) {
    var users []User
    err := db.Model(&User{}).Preload("CreditCard").Find(&users).Error
    return users, err
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
  // use UserName as foreign key
}

type CreditCard struct {
  gorm.Model
  Number   string
  UserName string
}
```

## Переопределить связи

По умолчанию принадлежащая сущность сохранит первичный ключ модели `has one` во внешний ключ, вы можете изменить это, чтобы сохранялось в другое поле, например `Name` как в примере ниже.

Вы можете изменить поле связи с помощью тега `references`, например:

```go
type User struct {
  gorm.Model
  Name       string     `gorm:"index"`
  CreditCard CreditCard `gorm:"foreignKey:UserName;references:name"`
}

type CreditCard struct {
  gorm.Model
  Number   string
  UserName string
}
```

## CRUD с has one

Пожалуйста, смотрите [Режим связи](associations.html#Association-Mode) для работы с `has one` связями

## Нетерпеливая загрузка

GORM позволяет использовать нетерпеливую загрузку для связей `has one` с помощью `Preload` или `Joins`, смотрите [Предзагрузка (Нетерпеливая загрузка)](preload.html) для подробностей

## Самосвязанный Has One

```go
type User struct {
  gorm.Model
  Name      string
  ManagerID *uint
  Manager   *User
}
```

## Ограничения внешних ключей

Вы можете настроить `OnUpdate`, `OnDelete` ограничения с помощью тега `constraint`, они будут созданы при миграции с помощью GORM, например:

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

You are also allowed to delete selected has one associations with `Select` when deleting, checkout [Delete with Select](associations.html#delete_with_select) for details
