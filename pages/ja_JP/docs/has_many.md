---
title: Has Many
layout: page
---

## Has Many

`has many` アソシエーションは別のモデルとの1対多となる関連を設定します。`has one` と異なり、所有する側となるモデルは0個以上のモデルのインスタンスを保有します。

例えば、ユーザーとクレジットカードのモデルがあり、各ユーザーはクレジットカードを複数持つことができる場合は以下のようになります。

### Declare
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

### Retrieve
```go
// Retrieve user list with eager loading credit cards
func GetAll(db *gorm.DB) ([]User, error) {
    var users []User
    err := db.Model(&User{}).Preload("CreditCards").Find(&users).Error
    return users, err
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

クレジットカードがあるユーザに与えられたとする場合、GORMはユーザの `ID` をクレジットカードの `UserID` フィールドに保存します。

`references` タグを設定することで、対象となるフィールドを変更することができます。

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


## Has ManyリレーションでのCRUD処理

Has many リレーションを使った処理の詳細については [Association Mode](associations.html#Association-Mode) を参照してください。

## Eager Loading

GORMでは、 `Preload` を使うことで、has manyリレーションの Eager Loadingを行うことができます。詳細については [Preload (Eager loading)](preload.html) を参照してください。

## Has Many での自己参照

```go
type User struct {
  gorm.Model
  Name      string
  ManagerID *uint
  Team      []User `gorm:"foreignkey:ManagerID"`
}
```

## 外部キー制約

`constraint` タグを使用することで、 `OnUpdate`, `OnDelete` の制約を掛けることができます。指定した制約はGORMを使ったマイグレーション実行時に作成されます。例：

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

削除時に `Select` を使用することで、 指定した has many の関連も削除することができます。詳細については [Delete with Select](associations.html#delete_with_select) を参照してください。
