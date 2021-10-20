---
title: Has Many
layout: page
---

## Has Many

`has many` アソシエーションは別のモデルとの1対多となる関連を設定します。`has one` と異なり、所有する側となるモデルは0個以上のモデルのインスタンスを保有します。

例えば、ユーザーとクレジットカードのモデルがあり、各ユーザーはクレジットカードを複数持つことができる場合は以下のようになります。

```go
// User は複数の CreditCards を持ちます。UserID は外部キーとなります。
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

## 外部キーのデフォルト設定を上書きする

`has many` リレーションを定義するには、外部キーが必要となります。 デフォルトの外部キーの名前は、所有する側のモデルの型名とそのモデルの主キーのフィールドの名前です。

例えば、 `User` に属するモデルを定義するには、外部キーは `UserID` でなければなりません。

別のフィールドを外部キーとして使用するには、 `foreignKey` タグを使用してカスタマイズします。例：

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

## 参照フィールドのデフォルト設定を上書きする

GORMは通常、所有する側のモデルの主キーをリレーションの外部キーの値として使用します。上記の例では、 `User` の `ID` がそれに該当します。

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

db.Create(&Dog{Name: "dog1", Toy: []Toy{{Name: "toy1"}, {Name: "toy2"}}})
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
