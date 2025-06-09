---
title: En a un (has one)
layout: page
---

## En a un (has one)

Une association `en a un` met en place une relation un à un avec un autre modèle, mais avec une sémantique quelque peu différente (et des conséquences). Cette association indique que chaque instance d'un modèle contient ou possède une instance d'un autre modèle.

Par exemple, si votre application contient des utilisateurs et des cartes de crédit, et que chaque utilisateur peu avoir qu'une seule carte de crédit.

### Déclarer
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

### Retrieve
```go

```

## Override Foreign Key

.

The field's name is usually generated with `has one` model's type plus its `primary key`, for the above example it is `UserID`.

When you give a credit card to the user, it will save the User's `ID` into its `UserID` field.

If you want to use another field to save the relationship, you can change it with tag `foreignKey`, e.g:

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

## Override References

By default, the owned entity will save the `has one` model's primary key into a foreign key, you could change to save another field's value, like using `Name` for the below example.

You are able to change it with tag `references`, e.g:

```go
type User struct {
  gorm.Model
  Name       string     `gorm:"index"`
  CreditCard CreditCard `gorm:"foreignKey:UserName;references:Name"`
}

type CreditCard struct {
  gorm.Model
  Number   string
  UserName string
}
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

You can setup `OnUpdate`, `OnDelete` constraints with tag `constraint`, it will be created when migrating with GORM, for example:

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
