---
title: Has One
layout: page
---

## Has One

`has one` は、別のモデルと一対一となる関連を設定します。関連するモデルによって、セマンティクス（と因果関係）は多少異なります。 このアソシエーションは、モデルの各インスタンスが別のモデルの1つのインスタンスを含んでいるか、または所有していることを示します。

例えば、ユーザーとクレジットカードのモデルがあり、各ユーザーはクレジットカードを1枚しか持つことができないとします。

### Declare
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

### Retrieve
```go
// Retrieve user list with edger loading credit card
func GetAll(db *gorm.DB) ([]User, error) {
    var users []User
    err := db.Model(&User{}).Preload("CreditCard").Find(&users).Error
    return users, err
}
```

## 外部キーのデフォルト設定を上書きする

`has one`を定義する場合、外部キーフィールドも存在する必要があります。所有側のモデルは、この属するモデルの主キーをこのフィールドへ保存します。

そのフィールドの名前は通常、 `has one`を持つモデルの型名に`primary key`を足したものとして作成されます。上記の例では `UserID`です。

ユーザーにクレジットカードを渡すと、ユーザーの `ID` が `UserID` フィールドに保存されます。

別のフィールドを使用したい場合は、`foreignKey`タグで変更できます。例：

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

## 参照フィールドのデフォルト設定を上書きする

デフォルトでは, 所有されているエンティティは `has one`モデルの主キーを外部キーとして保持します。以下の`Name`の例のように別のフィールドを保持するように変更することもできます。

`references` タグを設定することで、対象となるフィールドを変更することができます。

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

GORMは `has one` と `has many` アソシエーションにおいて、polymorphism associationをサポートしています。所有する側のエンティティのテーブル名が polymorphic type のフィールドに保存され、主キーが polymorphic 用のフィールドに保存されます。

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

`polymorphicValue`タグを使用して、polymorphic typeとして登録される値を変更できます。例：

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

## Has OneリレーションでのCRUD処理

`Has one` リレーションを使った処理の詳細については [Association Mode](associations.html#Association-Mode) を参照してください。

## Eager Loading

GORMでは、 `Preload` または `Joins` を使うことで、`has one` リレーションの Eager Loadingを行うことができます。詳細については [Preload (Eager loading)](preload.html) を参照してください。

## Has One での自己参照

```go
type User struct {
  gorm.Model
  Name      string
  ManagerID *uint
  Manager   *User
}
```

## 外部キー制約

`constraint` タグを使用することで、 `OnUpdate`, `OnDelete` の制約を掛けることができます。指定した制約はGORMを使ったマイグレーション実行時に作成されます。例：

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

削除時に `Select` を使用することで、 指定した has one の関連も削除することができます。詳細については [Delete with Select](associations.html#delete_with_select) を参照してください。
