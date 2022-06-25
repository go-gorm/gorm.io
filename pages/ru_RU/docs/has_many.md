---
title: Has Many (имеет много)
layout: страница
---

## Has Many (имеет много)

Связь `has many (имеет много)` устанавливает связь с другой моделью, в отличие от `has one (имеет одну)`, владелец может не иметь или иметь много экземпляров моделей.

Например, если ваше приложение включает пользователей и кредитные карты, и каждый пользователь может иметь много кредитных карт.

### Declare
```go
// User имеет много CreditCards, UserID это внешний ключ
type User struct {
  gorm.Model
  CreditCards []CreditCard
}

type CreditCard struct {
  gorm.Model
  Number string
  UserID uint
}
```

### Retrieve
```go
// Retrieve user list with edger loading credit cards
func GetAll(db *gorm.DB) ([]User, error) {
    var users []User
    err := db.Model(&User{}).Preload("CreditCards").Find(&users).Error
    return users, err
}
```

## Переопределить внешний ключ

Чтобы определить связь `has many (имеет много)`, должен существовать внешний ключ. Имя внешнего ключа по умолчанию - это имя типа владельца плюс имя поля первичного ключа

Например, для определения модели, принадлежащей `User`, внешний ключ должен быть `UserID`.

Чтобы использовать другое поле в качестве внешнего ключа, вы можете настроить его с помощью тега `foreignKey`, например:

```go
type User struct {
  gorm.Model
  CreditCards []CreditCard `gorm:"foreignKey:UserRefer"`
}

type CreditCard struct {
  gorm.Model
  Number    string
  UserRefer uint
}
```

## Переопределить связи

GORM обычно использует первичный ключ владельца в качестве значения внешнего ключа, для приведенного выше примера это `ID` модели `User`,

При назначении кредитных карт пользователю, GORM сохранит `ID` пользователя в поле `UserID`.

Вы можете изменить поле связи с помощью тега `references`, например:

```go
type User struct {
  gorm.Model
  MemberNumber string
  CreditCards  []CreditCard `gorm:"foreignKey:UserNumber;references:MemberNumber"`
}

type CreditCard struct {
  gorm.Model
  Number     string
  UserNumber string
}
```

## Полиморфическая связь

GORM поддерживает полиморфическую связь между `has one (имеет одну)` и `has many (имеет много)`, он сохранит название таблицы принадлежащего сущности в поле полиморфического типа, значение первичного ключа в полиморфическое поле

```go
type Dog struct {
  ID   int
  Name string
  Toys []Toy `gorm:"polymorphic:Owner;"`
}

type Toy struct {
  ID        int
  Name      string
  OwnerID   int
  OwnerType string
}

db.Create(&Dog{Name: "dog1", Toys: []Toy{{Name: "toy1"}, {Name: "toy2"}}})
// INSERT INTO `dogs` (`name`) VALUES ("dog1")
// INSERT INTO `toys` (`name`,`owner_id`,`owner_type`) VALUES ("toy1","1","dogs"), ("toy2","1","dogs")
```

Вы можете изменить значение типа полиморфических меток тегом `polymorphicValue`, например:

```go
type Dog struct {
  ID   int
  Name string
  Toys []Toy `gorm:"polymorphic:Owner;polymorphicValue:master"`
}

type Toy struct {
  ID        int
  Name      string
  OwnerID   int
  OwnerType string
}

db.Create(&Dog{Name: "dog1", Toy: []Toy{{Name: "toy1"}, {Name: "toy2"}}})
// INSERT INTO `dogs` (`name`) VALUES ("dog1")
// INSERT INTO `toys` (`name`,`owner_id`,`owner_type`) VALUES ("toy1","1","master"), ("toy2","1","master")
```

## CRUD с has many

Пожалуйста, смотрите [режим связей](associations.html#Association-Mode) для работы с has many (имеет много) связями

## Нетерпеливая загрузка

GORM позволяет использовать нетерпеливую загрузку для связей has many (имеет много) с помощью `Preload`, смотрите [Предзагрузка (Нетерпеливая загрузка)](preload.html) для подробностей

## Самосвязанный Has Many

```go
type User struct {
  gorm.Model
  Name      string
  ManagerID *uint
  Team      []User `gorm:"foreignkey:ManagerID"`
}
```

## Ограничения внешних ключей

Вы можете настроить `OnUpdate`, `OnDelete` ограничения с помощью тега `constraint`, они будут созданы при миграции с помощью GORM, например:

```go
type User struct {
  gorm.Model
  CreditCards []CreditCard `gorm:"constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`
}

type CreditCard struct {
  gorm.Model
  Number string
  UserID uint
}
```

Вы также можете удалить выбранные ассоциации has many с помощью `Select` при удалении, ознакомьтесь с [Delete with Select](associations.html#delete_with_select) для подробностей
