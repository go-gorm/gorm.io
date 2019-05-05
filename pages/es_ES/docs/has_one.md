---
title: Has One
layout: page
---

## Has One

Una asociación `has one` también establece una conexión uno a uno con otro modelo, pero con semántica (y consecuencias) diferentes. Esta asociación indica que cada instancia de un modelo contiene o posee una instancia de otro modelo.

For example, if your application includes users and credit cards, and each user can only have one credit card.

```go
// User has one CreditCard, CreditCardID is the foreign key
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

## Clave Foránea

For a `has one` relationship, a foreign key field must also exist, the owned will save the primary key of the model belongs to it into this field.

The field's name is usually generated with `has one` model's type plus its `primary key`, for the above example it is `UserID`.

When you give a credit card to the user, its will save the User's `ID` into its `UserID` field.

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

## Asociación ForeignKey

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

## Asociación de Polimorfismo

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

Nota: las asociaciones polimórficas belongs-to y many-to-many NO son compatibles y producirán errores.

## Trabajando con Has One

You could find `has one` associations with `Related`

```go
var card CreditCard
db.Model(&user).Related(&card, "CreditCard")
//// SELECT * FROM credit_cards WHERE user_id = 123;
// 123 es la clave principal del usuario
// CreditCard es el nombre del campo del usuario, es decir obtener las relaciones CreditCard del usuario y llenar en una tarjeta variable
// si es igual que el nombre de tipo de la variable, como en el ejemplo anterior, podría omitirse, tal como:
db.Model(&user).Related(&card)
```

Para un uso avanzado, consulte [Modo de Asociación](/docs/associations.html#Association-Mode)