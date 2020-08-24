---
title: Belongs To
layout: page
---

## Gehört zu

Eine `belongs to` Zuordnung stellt eine Einzel-zu-Eins-Verbindung mit einem anderen Modell her, so dass jede Instanz des deklarierenden Modells zu einer Instanz des anderen Modells gehört.

Zum Beispiel, wenn Ihre Anwendung Benutzer und Unternehmen umfasst, und jeder Benutzer genau einem Unternehmen zugewiesen werden kann

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

Für das obige Beispiel, um das `User` Modell zu definieren, dass zu `Company` gehört. Dder Fremdschlüssel sollte, nach Konvention `CompanyID` sein

GORM ermöglicht es, den Fremdschlüssel nach Bedarf anzupassen:

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

Wenn Sie einer `Company` einen `User` zuweisen, speichert GORM die `ID` der `Company` in das Feld `CompanyID` des `User`.

Es ist möglich die Referenz mit `references` zu ändern, z.B. :

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

## CRUD mit zugehörigkeit

Weiteführende Informaionen um mit `belongs to` finded sich in [Association Mode](associations.html#Association-Mode)

## Voraus-Laden

GORM erlaubt es `belongs to` Zugehörigkeiten mit `Preload` or `Joins` im Voraus zu laden. Weiteführende Informationen dazu, [Preloading (Eager loading)](preload.html)

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
