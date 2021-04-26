---
title: Belongs To
layout: page
---

## Belongs To

`belongs to` 会与另一个模型建立了一对一的连接。 这种模型的每一个实例都“属于”另一个模型的一个实例。

例如，您的应用包含 user 和 company，并且每个 user 能且只能被分配给一个 company。下面的类型就表示这种关系。 注意，在 `User` 对象中，有一个和 `Company` 一样的 `CompanyID`。 By default, the `CompanyID` is implicitly used to create a foreign key relationship between the `User` and `Company` tables, and thus must be included in the `User` struct in order to fill the `Company` inner struct.

```go
// `User` 属于 `Company`，`CompanyID` 是外键
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

Refer to [Eager Loading](belongs_to.html#Eager-Loading) for details on populating the inner struct.

## 重写外键

To define a belongs to relationship, the foreign key must exist, the default foreign key uses the owner's type name plus its primary field name.

For the above example, to define the `User` model that belongs to `Company`, the foreign key should be `CompanyID` by convention

GORM provides a way to customize the foreign key, for example:

```go
type User struct {
  gorm.Model
  Name         string
  CompanyRefer int
  Company      Company `gorm:"foreignKey:CompanyRefer"`
  // 使用 CompanyRefer 作为外键
}

type Company struct {
  ID   int
  Name string
}
```

## 重写引用

For a belongs to relationship, GORM usually uses the owner's primary field as the foreign key's value, for the above example, it is `Company`'s field `ID`.

When you assign a user to a company, GORM will save the company's `ID` into the user's `CompanyID` field.

You are able to change it with tag `references`, e.g:

```go
type User struct {
  gorm.Model
  Name      string
  CompanyID string
  Company   Company `gorm:"references:Code"` // 使用 Code 作为引用
}

type Company struct {
  ID   int
  Code string
  Name string
}
```

## Belongs to 的 CRUD

Please checkout [Association Mode](associations.html#Association-Mode) for working with belongs to relations

## 预加载

GORM allows eager loading belongs to associations with `Preload` or `Joins`, refer [Preloading (Eager loading)](preload.html) for details

## 外键约束

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
