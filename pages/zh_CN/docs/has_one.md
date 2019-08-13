---
title: Has One
layout: page
---

## Has One

一个 `has one` 关联与另一个 model 建立了一对一关系，但它和一对一关系有不同的语义（及结果）。 Has one 表示：model 的每一个示例都包含或拥有另一个 model 的示例。

例如，如果你的应用包含用户和信用卡，并且每个用户只能有一张信用卡。

```go
// 用户有一张信用卡，UserID 是外键
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

在 `has one` 关系中，必须存在一个外键字段，用于保存 `has one` 所属 model 的主键。

外键字段的名称通常使用 `has one` 所属模型加上它的 `主键` 生成，对于上面的例子，其外键名为 `UserID`.

当你为用户关联信用卡时，信用卡会保存用户的 `ID` 到它的 `UserID` 字段。

If you want to use another field to save the relationship, you can change it with tag `foreignkey`, e.g:

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

By default, the owned entity will save the `has one` model's primary into a foreign key, you could change to save another field, like use `Name` for below example.

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