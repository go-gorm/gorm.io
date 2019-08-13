---
title: Has Many
layout: page
---

## Has Many

在一个 `has many` 关联中，其也与另一个 model 建立了一对多关系，不同于 `has one`，model 的拥有者可以有零个或多个实例。

例如，你的应用包含了用户和信用卡，并且每个用户可以有多张信用卡。

```go
// 用户有多张信用卡， UserID 是外键
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

在 has many 关系中，被拥有 model 必须存在一个外键字段，默认的外键字段名称通常使用拥有者 model 加上它的主键（比如 UserID, CardID, 等）。

例如：定义一个属于 `User` 的 model，它的外键应该为 `UserID`.

要使用另一个字段作为外键，你可以通过标签 `foreignkey` 来定制它，例如：

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

GORM usually uses the owner's primary key as the foreign key's value, for above example, it is the `User`'s `ID`,

When you assign credit cards to a user, GORM will save the user's `ID` into credit cards' `UserID` field.

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

Note: polymorphic belongs-to and many-to-many are explicitly NOT supported, and will throw errors.

## Working with Has Many

You could find `has many` associations with `Related`

```go
db.Model(&user).Related(&emails)
//// SELECT * FROM emails WHERE user_id = 111; // 111 is user's primary key
```

For advanced usage, refer to [Association Mode](/docs/associations.html#Association-Mode)