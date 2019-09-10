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

## 外键

Foreign Key，在 has many 关系中，被拥有 model 必须存在一个外键字段，默认的外键字段名称通常使用其拥有者 model 加上它的主键（比如 UserID, CardID, 等）。

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

## 关联外键

Association ForeignKey，GORM 通常使用拥有者的主键作为外键的值，在上面的例子中，它是 `User` 的 `ID`.

当你为用户关联信用卡时，GORM 会保存用户的 `ID` 到信用卡的 `UserID` 字段。

您可以通过标签 `association_foreignkey` 来改变它，例如：

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

## 多态关联

Polymorphism Association，GORM 支持 has many 和 has one 的多态关联。

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

注意：many-to-many 明确的不支持多态关联，如果使用会抛出错误。

## Has Many 的使用

你可以通过 `Related` 使用 `has many` 关联。

```go
db.Model(&user).Related(&emails)
//// SELECT * FROM emails WHERE user_id = 111; // 111 is user's primary key
```

高级用法请参阅： [关联模式](/docs/associations.html#Association-Mode)