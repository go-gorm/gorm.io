---
title: Has One
layout: page
---

## Has One

`has one` は、別のモデルとの一対一の接続を設定しますが、セマンティクス（とその結果）は多少異なります。 このアソシエーションは、モデルの各インスタンスが別のモデルの1つのインスタンスを含んでいるか、または所有していることを示します。

例えば、ユーザーとクレジットカードのモデルがあり、各ユーザーはクレジットカードを1枚しか持つことができないとします。

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

別のフィールドを使用したい場合は、`foreignKey`タグで変更できます。例：

```go
type User struct {
  gorm.Model
  CreditCard CreditCard `gorm:"foreignKey:UserName"`
  // UserNameを外部キーとして利用する。
}

type CreditCard struct {
  gorm.Model
  Number   string
  UserName string
}
```

## Override References

デフォルトでは, 所有されているエンティティは `has one`モデルの主キーを外部キーとして保持します。以下の`Name`の例のように別のフィールドを保持するように変更することもできます。

`references`タグを用いて変更することもできます。

```go
type User struct {
  gorm.Model
  Name       string     `gorm:"index"`
  CreditCard CreditCard `gorm:"foreignkey:UserName;references:name"`
}

type CreditCard struct {
  gorm.Model
  Number   string
  UserName string
}
```

## Polymorphism Association

GORM supports polymorphism association for `has one` and `has many`, it will save owned entity's table name into polymorphic type's field, primary key into the polymorphic field

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

`polymorphicValue`タグを使用して、ポリモーフィック型の値を変更できます。例：

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

`has one`と利用するには[Association Mode](associations.html#Association-Mode)を参照してください。

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
