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

## 外部キーのデフォルト設定を上書きする

Belongs to リレーションを定義するには、外部キーが存在する必要があります。デフォルトの外部キーでは、所有する側にあるモデルの型名とそのモデルの主キーのフィールド名を使用します。

上記の例では、`Company` に属する `User` モデルを定義する際、規約に従い、外部キーを `CompanyID` としています。

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

## 参照フィールドのデフォルト設定を上書きする

Belongs to リレーションにおいて、GORMは通常、所有する側にあるモデルの主キーをリレーションの外部キーの値として使用します。 上記の例では `Company` の `ID` がそれに該当します。

UserをCompanyに割り当てた場合、GORMはCompanyの `ID` をUserの `CompanyID`フィールドに保存します。

`references` タグを設定することで、対象となるフィールドを変更することができます。

```go
type User struct {
  gorm.Model
  Name      string
  CompanyID string
  Company   Company `gorm:"references:Code"` // Codeを参照として使用する
}

type Company struct {
  ID   int
  Code string
  Name string
}
```

{% note warn %}
**NOTE** GORM usually guess the relationship as `has one` if override foreign key name already exists in owner's type, we need to specify `references` in the `belongs to` relationship.
{% endnote %}

```go
type User struct {
  gorm.Model
  Name      string
  CompanyID int
  Company   Company `gorm:"references:CompanyID"` // use Company.CompanyID as references
}

type Company struct {
  CompanyID   int
  Code        string
  Name        string
}
```

## Belongs ToリレーションでのCRUD処理

Belongs toリレーションを使った処理の詳細については [Association Mode](associations.html#Association-Mode) を参照してください。

## Eager Loading

GORMでは、 `Preload` または `Joins` を使うことで、belongs toリレーションの Eager Loadingを行うことができます。詳細については [Preload (Eager loading)](preload.html) を参照してください。

## 外部キー制約

`constraint` タグを使用することで、 `OnUpdate`, `OnDelete` の制約を掛けることができます。指定した制約はGORMを使ったマイグレーション実行時に作成されます。例：

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
