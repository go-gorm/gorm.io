---
title: Constraints
layout: page
---

GORM erlaubt Datenbankbedinungen mit einem Tag zu erstellen, Bedinungen werden erstellt wenn [AutoMigrate oder CreateTable mit GORM](migration.html)

## Prüfende Bedinung

Prüfende Bedinungen werden mit dem `check` tag erstellt

```go
type UserIndex struct {
    Name  string `gorm:"check:name_checker,name <> 'jinzhu'"`
    Name2 string `gorm:"check:name <> 'jinzhu'"`
    Name3 string `gorm:"check:,name <> 'jinzhu'"`
}
```

## Index Bedinung

Weitere Infos, [Database Indexes](indexes.html)

## Fremdschlüssel Bedinung

GORM wird Fremdschlüssel Bedinungen für Zugehörigkeiten erstellen, Sie können diese Funktion während der Initialisierung deaktivieren:

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DisableForeignKeyConstraintWhenMigrating: true,
})
```

GORM ermöglicht es Ihnen die Einrichtung von Fremdschlüssel Bedinungen `OnUpdate`, `OnDelete` Option mit dem Tag `constraint`, z.B. :

```go
type User struct {
  gorm.Model
  CompanyID  int
  Company    Company    `gorm:"constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`
  CreditCard CreditCard `gorm:"constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`
}

type CreditCard struct {
  gorm.Model
  Number string
  UserID uint
}

type Company struct {
  ID   int
  Name string
}
```
