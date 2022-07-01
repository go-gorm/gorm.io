---
title: Belongs To
layout: page
---

## Gehört zu

Eine `belongs to` Zuordnung stellt eine Einzel-zu-Eins-Verbindung mit einem anderen Modell her, so dass jede Instanz des deklarierenden Modells zu einer Instanz des anderen Modells gehört.

For example, if your application includes users and companies, and each user can be assigned to exactly one company, the following types represent that relationship. Notice here that, on the `User` object, there is both a `CompanyID` as well as a `Company`. By default, the `CompanyID` is implicitly used to create a foreign key relationship between the `User` and `Company` tables, and thus must be included in the `User` struct in order to fill the `Company` inner struct.

```go
// `User` gehört zu `Company`, `CompanyID` ist der Fremdschlüssel
Typ User struct {
  gorm.Model
  Name string
  CompanyID int
  Company Company
}

Typ Company struct {
  ID int
  Name string
}
```

Refer to [Eager Loading](belongs_to.html#Eager-Loading) for details on populating the inner struct.

## Fremdschlüssel Überschreiben

To define a belongs to relationship, the foreign key must exist, the default foreign key uses the owner's type name plus its primary field name.

For the above example, to define the `User` model that belongs to `Company`, the foreign key should be `CompanyID` by convention

GORM provides a way to customize the foreign key, for example:

```go
type User struct {
  gorm.Model
  Name         string
  CompanyRefer int
  Company      Company `gorm:"foreignKey:CompanyRefer"`
  // benutze CompanyRefer als Fremdschlüssel
}

type Company struct {
  ID   int
  Name string
}
```

## Referenz Überschreiben

For a belongs to relationship, GORM usually uses the owner's primary field as the foreign key's value, for the above example, it is `Company`'s field `ID`.

When you assign a user to a company, GORM will save the company's `ID` into the user's `CompanyID` field.

You are able to change it with tag `references`, e.g:

```go
type User struct {
  gorm.Model
  Name      string
  CompanyID string
  Company   Company `gorm:"references:Code"` // benutze Code als Referenz
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
  CompanyID string
  Company   Company `gorm:"references:CompanyID"` // use Company.CompanyID as references
}

type Company struct {
  CompanyID   int
  Code        string
  Name        string
}
```

## CRUD mit zugehörigkeit

Please checkout [Association Mode](associations.html#Association-Mode) for working with belongs to relations

## Voraus-Laden

GORM allows eager loading belongs to associations with `Preload` or `Joins`, refer [Preloading (Eager loading)](preload.html) for details

## Fremdschlüssel Bedingungen

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
