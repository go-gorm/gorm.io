---
title: Has One
layout: page
---

## Has One

`has one` は、別のモデルとの一対一の接続を設定しますが、セマンティクス（とその結果）は多少異なります。 このアソシエーションは、モデルの各インスタンスが別のモデルの1つのインスタンスを含んでいるか、または所有していることを示します。

たとえば、ユーザーとクレジットカードのモデルがあり、各ユーザーはクレジットカードを1枚しか持つことができないとします：

```go
// Userは1つだけCreditCardを持ちます。CreditCardIDは外部キーです。
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

## Override Foreign Key

`has one`を定義する場合、外部キーフィールドも存在する必要があります。所有側のモデルは、この属するモデルの主キーをこのフィールドへ保存します。

そのフィールドの名前は通常、 `has one`を持つモデルの型名に`primary key`を足したものとして作成されます。上記の例では `UserID`です。

ユーザーにクレジットカードを渡すと、ユーザーの `ID` が `UserID` フィールドに保存されます。

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

By default, the owned entity will save the `has one` model's primary key into a foreign key, you could change to save another field, like using `Name` for the below example.

You are able to change it with tag `references`, e.g:

```go
type User struct {
  gorm.Model
  Name       string     `sql:"index"`
  CreditCard CreditCard `gorm:"foreignkey:UserName;references:name"`
}

type CreditCard struct {
  gorm.Model
  Number   string
  UserName string
}
```

## Polymorphism Association

GORM supports polymorphism association for `has one` and `has many`, it will save owned entity's table name into polymorphic type's field, primary key into the polymorphic field, primary key value into the polymorphic field

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

db.Create(&Dog{Name: "dog1", Toy: Toy{Name: "toy1"}})
// INSERT INTO `dogs` (`name`) VALUES ("dog1")
// INSERT INTO `toys` (`name`,`owner_id`,`owner_type`) VALUES ("toy1","1","dogs")
```

You can change the polymorphic type value with tag `polymorphicValue`, for example:

```go
type Dog struct {
  ID   int
  Name string
  Toy  Toy `gorm:"polymorphic:Owner;polymorphicValue:master"`
}

type Toy struct {
  ID        int
  Name      string
  OwnerID   int
  OwnerType string
}

db.Create(&Dog{Name: "dog1", Toy: Toy{Name: "toy1"}})
// INSERT INTO `dogs` (`name`) VALUES ("dog1")
// INSERT INTO `toys` (`name`,`owner_id`,`owner_type`) VALUES ("toy1","1","master")
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

You can setup `OnUpdate`, `OnDelete` constraints with tag `constraint`, for example:

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
