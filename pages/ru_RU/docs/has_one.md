---
title: Has One
layout: страница
---

## Has One

Связь `has one` "имеет одну" также делает связь один к одному с другой моделью, но с несколько разными семантиками (и последствиями). Эта ассоциация указывает, что каждый экземпляр модели содержит или обладает одним из экземпляров другой модели.

Например, если ваше приложение включает в себя пользователей и кредитные карты, и каждый пользователь может иметь одну кредитную карту.

```go
// User имеет одну CreditCard, CreditCardID это внешний ключ
type CreditCard struct {
    gorm.Model
    Number   string
    UserID   uint
}

type User struct {
    gorm.Model
    CreditCard   CreditCard
}
```

## Foreign Key

Для связи has one "имеет одну", поле внешнего ключа должно существовать, владелец будет сохранять первичный ключ принадлежащей поделив это поле.

Название поля генерируется с помощью `has one` типа модели плюс его `primary key` (первичный ключ), для примера выше это `UserID`.

Когда вы задаете кредитную карту модели пользователя, она сохранит `ID` кредитной карты в поле `CreditCardID`.

Если вы хотите использовать другое поле для сохранения отношений, вы можете изменить его с тегом `foreignkey`, например:

```go
type CreditCard struct {
    gorm.Model
    Number   string
    UserName string
}

type User struct {
    gorm.Model
    CreditCard CreditCard `gorm:"foreignkey:UserName"`
}
```

## Association ForeignKey

По умолчанию, сущность владелец сохранит `has one` первичный ключ модели во внешний ключ, для сохранения в другое поле вы можете изменить, например, использовать `Name` для примера ниже.

```go
type CreditCard struct {
    gorm.Model
    Number string
    UID    string
}

type User struct {
    gorm.Model
    Name       `sql:"index"`
    CreditCard CreditCard `gorm:"foreignkey:uid;association_foreignkey:name"`
}
```

## Polymorphism Association

Supports polymorphic `has many` and `has one` associations.

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
```

Note: polymorphic belongs-to and many-to-many are explicitly NOT supported, and will throw errors.

## Working with Has One

You could find `has one` associations with `Related`

```go
var card CreditCard
db.Model(&user).Related(&card, "CreditCard")
//// SELECT * FROM credit_cards WHERE user_id = 123; // 123 is user's primary key
// CreditCard is user's field name, it means get user's CreditCard relations and fill it into variable card
// If the field name is same as the variable's type name, like above example, it could be omitted, like:
db.Model(&user).Related(&card)
```

For advanced usage, refer [Association Mode](/docs/associations.html#Association-Mode)