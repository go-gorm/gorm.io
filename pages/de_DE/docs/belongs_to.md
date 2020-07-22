---
title: Belongs To
layout: page
---

## Gehört zu

Eine `belongs to` Zuordnung stellt eine Einzel-zu-Eins-Verbindung mit einem anderen Modell her, so dass jede Instanz des deklarierenden Modells zu einer Instanz des anderen Modells gehört.

Zum Beispiel, wenn Ihre Anwendung Benutzer und Unternehmen umfasst, jeder Benutzer genau einem Unternehmen zugewiesen werden kann

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

## Fremdschlüssel Überschreiben

Um eine Beziehung zu definieren, muss der Fremdschlüssel existieren, der vordefinierte Fremdschlüssel verwendet den Namen des Eigentümers, plus seinen primären Feldnamen.

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

Für eine `belongs to` Beziehung verwendet GORM normalerweise das Primärfeld des Besitzers als Wert des Fremdschlüssels. Für das obige Beispiel ist es das `ID` Feld von `Company`.

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

You can setup `OnUpdate`, `OnDelete` constraints with tag `constraint`, for example:

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
