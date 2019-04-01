---
title: Has One
layout: страница
---
## Has One

Связь `has one` "имеет одну" также делает связь один к одному с другой моделью, но с несколько разными семантиками (и последствиями). Эта ассоциация указывает, что каждый экземпляр модели содержит или обладает одним из экземпляров другой модели.

Например, если ваше приложение включает в себя пользователей и кредитную карту, и каждый пользователь может иметь одну кредитную карту.

```go
// User имеет одну CreditCard, CreditCardID это внешний ключ
type User struct {
    gorm.Model
    CreditCard   CreditCard
  CreditCardID uint
}

type CreditCard struct {
    gorm.Model
    Number   string
}
```

## Foreign Key

Для связи has one "имеет одну", поле внешнего ключа должно существовать, владелец будет сохранять первичный ключ принадлежащей поделив это поле.

Имя поля обычно генерируется из типа поля `принадлежит к модели` плюс его `первичный ключ`, например `CreditCardID`

Когда вы задаете кредитную карту модели пользователя, она сохранит `ID` кредитной карты в поле `CreditCardID`.

Если вы хотите использовать другое поле для сохранения отношений, вы можете изменить его с тегом `foreignkey`, например:

```go
type User struct {
  gorm.Model
  CreditCard CreditCard `gorm:"foreignkey:CardRefer"`
  CardRefer uint
}

type CreditCard struct {
    gorm.Model
    Number string
}
```

## Association ForeignKey

By default, the owner will save the `belongs to model`'s primary into a foreign key, you could change to save another field, like use `Number` for below example.

```go
type User struct {
  gorm.Model
  CreditCard CreditCard `gorm:"association_foreignkey:Number"`
  CardRefer uint
}

type CreditCard struct {
    gorm.Model
    Number string
}
```

## Polymorphism Association

Supports polymorphic has-many and has-one associations.

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