---
title: Belongs To
layout: страница
---

## Один к одному

Отношение `один к одному` устанавливает связь один к одному с другой моделью, таким образом, чтобы каждый экземпляр объявленной модели "принадлежал" одному экземпляру другой модели.

Например, если в вашем приложении есть пользователи и компании, и каждый пользователь может быть только в одной компании, то следующие типы отражают это отношение. Notice here that, on the `User` object, there is both a `CompanyID` as well as a `Company`. By default, the `CompanyID` is implicitly used to create a foreign key relationship between the `User` and `Company` tables, and thus must be included in the `User` struct in order to fill the `Company` inner struct.

```go
// `User` belongs to `Company`, `CompanyID` это внешний ключ
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

## Переопределить внешний ключ

To define a belongs to relationship, the foreign key must exist, the default foreign key uses the owner's type name plus its primary field name.

For the above example, to define the `User` model that belongs to `Company`, the foreign key should be `CompanyID` by convention

GORM provides a way to customize the foreign key, for example:

```go
type User struct {
  gorm.Model
  Name         string
  CompanyRefer int
  Company      Company `gorm:"foreignKey:CompanyRefer"`
  // использовать CompanyRefer как внешний ключ
}

type Company struct {
  ID   int
  Name string
}
```

## Переопределить ссылки

For a belongs to relationship, GORM usually uses the owner's primary field as the foreign key's value, for the above example, it is `Company`'s field `ID`.

When you assign a user to a company, GORM will save the company's `ID` into the user's `CompanyID` field.

You are able to change it with tag `references`, e.g:

```go
type User struct {
  gorm.Model
  Name      string
  CompanyID string
  Company   Company `gorm:"references:Code"` // использовать Code как ссылку
}

type Company struct {
  ID   int
  Code string
  Name string
}
```

## CRUD с Belongs To

Please checkout [Association Mode](associations.html#Association-Mode) for working with belongs to relations

## Нетерпеливая загрузка

GORM allows eager loading belongs to associations with `Preload` or `Joins`, refer [Preloading (Eager loading)](preload.html) for details

## Ограничения внешних ключей

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
