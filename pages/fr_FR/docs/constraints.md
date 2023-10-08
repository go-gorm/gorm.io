---
title: Contraintes
layout: page
---

GORM permet de créer de base de données avec des contraintes, les contraintes sont créées quand  [AutoMigrate ou CreateTable avec GORM](migration.html)

## Contrainte CHECK

Créer les contraintes CHECK avec le tag `check`

```go
type UserIndex struct {
    Name  string `gorm:"check:name_checker,name <> 'jinzhu'"`
    Name2 string `gorm:"check:name <> 'jinzhu'"`
    Name3 string `gorm:"check:,name <> 'jinzhu'"`
}
```

## Contrainte Index

Checkout [Database Indexes](indexes.html)

## Contrainte clé étrangère

GORM crée des contraintes sur la clé étrangère pour les associations, vous pouvez désactiver cette fonctionnalité lors d'initialisation :

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DisableForeignKeyConstraintWhenMigrating: true,
})
```

GORM vous permet de configurer les contraintes sur la clé étrangère avec `OnDelete`, `OnUpdate` avec le tag en option wit`constraint`, par exemple:

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
