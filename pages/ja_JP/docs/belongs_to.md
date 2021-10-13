---
title: Belongs To
layout: page
---

## Belongs To

`belongs to`アソシエーションは、モデルの各インスタンスが他のモデルの1つのインスタンスに "属する "ように、他のモデルとの1対1の接続を設定します。

たとえばユーザと会社が存在するアプリケーションがあり、各ユーザは1つの会社に所属する場合、以下のモデル定義はその関係性を表します。 ここで注意が必要なのは、 `User` オブジェクトには、 `CompanyID` と `Company` の両方がある点です。 デフォルトでは、 `CompanyID` は `User` と `Company` 間の外部キーを使った関連の作成に暗黙的に使われます。従って、`Company` の情報を埋めるためにCompanyID は `User` に含まれる必要があります。

```go
// `User`は`Company`に属します。 `CompanyID`は外部キーです。
type User struct {
  gorm.Model
  Name      string
  CompanyID int
  Company   Company
}

type Company struct {
  ID   int
  Name string
}
```

構造体内部にある別の構造体の読み込みの詳細については、 [Eager Loading](belongs_to.html#Eager-Loading) を参照してください。

## Override Foreign Key

To define a belongs to relationship, the foreign key must exist, the default foreign key uses the owner's type name plus its primary field name.

For the above example, to define the `User` model that belongs to `Company`, the foreign key should be `CompanyID` by convention

GORM provides a way to customize the foreign key, for example:

```go
type User struct {
  gorm.Model
  Name         string
  CompanyRefer int
  Company      Company `gorm:"foreignKey:CompanyRefer"`
  // CompanyReferを外部キーとして利用する。
}

type Company struct {
  ID   int
  Name string
}
```

## Override References

For a belongs to relationship, GORM usually uses the owner's primary field as the foreign key's value, for the above example, it is `Company`'s field `ID`.

When you assign a user to a company, GORM will save the company's `ID` into the user's `CompanyID` field.

You are able to change it with tag `references`, e.g:

```go
type User struct {
  gorm.Model
  Name      string
  CompanyID string
  Company   Company `gorm:"references:Code"` // use Code as references
}

type Company struct {
  ID   int
  Code string
  Name string
}
```

## CRUD with Belongs To

Please checkout [Association Mode](associations.html#Association-Mode) for working with belongs to relations

## Eager Loading

GORM allows eager loading belongs to associations with `Preload` or `Joins`, refer [Preloading (Eager loading)](preload.html) for details

## FOREIGN KEY Constraints

You can setup `OnUpdate`, `OnDelete` constraints with tag `constraint`, it will be created when migrating with GORM, for example:

```go
type User struct {
  gorm.Model
  Name      string
  CompanyID int
  Company   Company `gorm:"constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`
}

type Company struct {
  ID   int
  Name string
}
```
