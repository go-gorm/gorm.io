---
title: Has One
layout: page
---
## Has One

Una asociación `has one` también establece una conexión uno a uno con otro modelo, pero con semántica (y consecuencias) diferentes. Esta asociación indica que cada instancia de un modelo contiene o posee una instancia de otro modelo.

Por ejemplo, si su aplicación incluye usuarios y tarjetas de crédito, y cada usuario sólo puede tener una tarjeta de crédito.

```go
// El usuario tiene una tarjeta de crédito, CreditCardID es la clave foránea type User struct {     gorm.Model     CreditCard CreditCard   CreditCardID uint } type CreditCard struct {     gorm.Model     Number string }
```

## Clave Foránea

Para una relación has one, también debe existir un campo de clave foránea, el usuario guardará la clave primaria del modelo que le pertenece en este campo.

The field's name usually is generated with `belongs to model`'s type plus its `primary key`, for above example, it is `CreditCardID`

When you give a credit card to the user, its will save the credit card's `ID` into its `CreditCardID` field.

If you want to use another field to save the relationship, you can change it with tag `foreignkey`, e.g:

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

By default, the owner will save the `belogns to model`'s primary into foreign key, you could change to save another field, like use `Number` for below example.

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

You could find `has one` assciations with `Related`

```go
var card CreditCard
db.Model(&user).Related(&card, "CreditCard")
//// SELECT * FROM credit_cards WHERE user_id = 123; // 123 is user's primary key
// CreditCard is user's field name, it means get user's CreditCard relations and fill it into variable card
// If the field name is same as the variable's type name, like above example, it could be omitted, like:
db.Model(&user).Related(&card)
```

For advanced usage, refer [Association Mode](/docs/associations.html#Association-Mode)