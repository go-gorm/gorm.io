---
title: Has Many
layout: page
---

## Has Many

A `has many` association also sets up a one-to-many connection with another model, unlike `has one`, the owner could have zero or many instances of models.

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

## Foreign Key

To define a has many relatinship, foreign key must exists, default foreign key's name is owner's type name plus its primary key.

For a above example, to define a model that belongs to `User`, the foreign key should be `UserID`.

To use another field as foreign key, you can customize it with tag `foreignkey`, e.g:

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

## Association ForeignKey

GORM usually use owner's primary key as the foreign key's value, for above example, it is `User`'s `ID`,

When you assign credit cards to a user, GORM will save user's `ID` into credit cards' `UserID` field.

You are able to change it with tag `association_foreignkey`, e.g:

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

## Polymorphism Association

Supports polymorphic has-many and has-one associations.

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

Note: polymorphic belongs-to and many-to-many are explicitly NOT supported, and will throw errors.

## Working with Has Many

You could find `has many` assciations with `Related`

```go
db.Model(&user).Related(&emails)
//// SELECT * FROM emails WHERE user_id = 111; // 111 is user's primary key
```

For advanced usage, refer [Association Mode](/docs/associations.html#Association-Mode)
