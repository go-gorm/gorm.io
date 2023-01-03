---
title: Has Many
layout: page
---

## Has Many

A `has many` association sets up a one-to-many connection with another model, unlike `has one`, the owner could have zero or many instances of models.

For example, if your application includes users and credit card, and each user can have many credit cards.

### Declare
```go
// User has many CreditCards, UserID is the foreign key
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
// Retrieve user list with eager loading credit cards
func GetAll(db *gorm.DB) ([]User, error) {
    var users []User
    err := db.Model(&User{}).Preload("CreditCards").Find(&users).Error
    return users, err
}
```

## Override Foreign Key

To define a `has many` relationship, a foreign key must exist. The default foreign key's name is the owner's type name plus the name of its primary key field

For example, to define a model that belongs to `User`, the foreign key should be `UserID`.

To use another field as foreign key, you can customize it with a `foreignKey` tag, e.g:

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

## Override References

GORM usually uses the owner's primary key as the foreign key's value, for the above example, it is the `User`'s `ID`,

When you assign credit cards to a user, GORM will save the user's `ID` into credit cards' `UserID` field.

You are able to change it with tag `references`, e.g:

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

## Polymorphism Association

GORM supports polymorphism association for `has one` and `has many`, it will save owned entity's table name into polymorphic type's field, primary key value into the polymorphic field

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

You can change the polymorphic type value with tag `polymorphicValue`, for example:

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

db.Create(&Dog{Name: "dog1", Toys: []Toy{{Name: "toy1"}, {Name: "toy2"}}})
// INSERT INTO `dogs` (`name`) VALUES ("dog1")
// INSERT INTO `toys` (`name`,`owner_id`,`owner_type`) VALUES ("toy1","1","master"), ("toy2","1","master")
```

## CRUD with Has Many

Please checkout [Association Mode](associations.html#Association-Mode) for working with has many relations

## Eager Loading

GORM allows eager loading has many associations with `Preload`, refer [Preloading (Eager loading)](preload.html) for details

## Self-Referential Has Many

```go
type User struct {
  gorm.Model
  Name      string
  ManagerID *uint
  Team      []User `gorm:"foreignkey:ManagerID"`
}
```

## FOREIGN KEY Constraints

You can setup `OnUpdate`, `OnDelete` constraints with tag `constraint`, it will be created when migrating with GORM, for example:

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

You are also allowed to delete selected has many associations with `Select` when deleting, checkout [Delete with Select](associations.html#delete_with_select) for details
