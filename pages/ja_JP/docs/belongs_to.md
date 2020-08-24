---
title: Belongs To
layout: page
---

## Belongs To

`belongs to`アソシエーションは、モデルの各インスタンスが他のモデルの1つのインスタンスに "属する "ように、他のモデルとの1対1の接続を設定します。

たとえば、アプリケーションにユーザーと会社が含まれ、各ユーザーが1つの会社に割り当てられる場合などです。

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

## Override Foreign Key

Belongs toを定義する場合、外部キーが存在する必要があります。デフォルトの外部キーは、所有型の型名にその主キーフィールド名を足したものです。

上記の例では、`Company`に属する`User`モデルを定義する際、規約に従い、外部キーを`CompanyID`とします。

GORMは外部キーをカスタマイズする方法を提供しています。例：

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

Belongs toを定義する場合、GORMは通常、所有側の主キーフィールドを外部キーの値として使用します、。上記の例では`Company`のフィールド`ID`を使用します。

UserをComponyに割り当てると、GORMはComponyの `ID` をUserの `CompanyID`フィールドに保存します。

`references`タグを用いて変更することもできます。

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

[Association Mode](associations.html#Association-Mode)を参照してください。

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
