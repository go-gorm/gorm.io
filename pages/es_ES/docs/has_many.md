---
title: Has Many
layout: page
---
## Has Many

Una asociación `has many` también establece una conexión de uno a muchos con otro modelo, a diferencia de `has one`, el propietario podría tener cero o muchas instancias de modelos.

For example, if your application includes users and credit card, and each user can have many credit cards.

```go
// User has many CreditCards, UserID is the foreign key
type User struct {
    gorm.Model
    CreditCards []CreditCard
}

type CreditCard struct {
    gorm.Model
    Number   string
    UserID  uint
}
```

## Clave Foránea

To define a has many relationship, a foreign key must exist. The default foreign key's name is the owner's type name plus the name of its primary key field (e.g. UserID, CardID, etc).

For example, to define a model that belongs to `User`, the foreign key should be `UserID`.

To use another field as foreign key, you can customize it with a `foreignkey` tag, e.g:

```go
type User struct {
    gorm.Model
    CreditCards []CreditCard `gorm:"foreignkey:UserRefer"`
}

type CreditCard struct {
    gorm.Model
    Number    string
  UserRefer uint
}
```

## Asociación ForeignKey

GORM usually uses the owner's primary key as the foreign key's value, for above example, it is the `User`'s `ID`,

When you assign credit cards to a user, GORM will save the user's `ID` into credit cards' `UserID` field.

Puede cambiarlo con la etiqueta `association_foreignkey`, por ejemplo:

```go
type User struct {
    gorm.Model
  MemberNumber string
    CreditCards  []CreditCard `gorm:"foreignkey:UserMemberNumber;association_foreignkey:MemberNumber"`
}

type CreditCard struct {
    gorm.Model
    Number           string
  UserMemberNumber string
}
```

## Asociación de Polimorfismo

GORM supports polymorphic has-many and has-one associations.

```go
  type Cat struct {
    ID    int
    Name  string
    Toy   []Toy `gorm:"polymorphic:Owner;"`
  }

  type Dog struct {
    ID   int
    Name string
    Toy  []Toy `gorm:"polymorphic:Owner;"`
  }

  type Toy struct {
    ID        int
    Name      string
    OwnerID   int
    OwnerType string
  }
```

Nota: las asociaciones polimórficas belongs-to y many-to-many NO son compatibles y producirán errores.

## Trabajando con Has Many

You could find `has many` associations with `Related`

```go
db.Model(&user).Related(&emails) //// SELECT * FROM emails WHERE user_id = 111; // 111 es la clave principal del usuario
```

For advanced usage, refer to [Association Mode](/docs/associations.html#Association-Mode)