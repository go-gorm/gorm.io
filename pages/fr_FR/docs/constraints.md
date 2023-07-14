---
title: Contraintes
layout: page
---

GORM permet de créer de base de données avec des contraintes, les contraintes sont créées quand  [AutoMigrate ou CreateTable avec GORM](migration.html)

## CHECK Constraint

Create CHECK constraints with tag `check`

```go
type UserIndex struct {
    Name  string `gorm:"check:name_checker,name <> 'jinzhu'"`
    Name2 string `gorm:"check:name <> 'jinzhu'"`
    Name3 string `gorm:"check:,name <> 'jinzhu'"`
}
```

## Index Constraint

Checkout [Database Indexes](indexes.html)

## Foreign Key Constraint

GORM will creates foreign keys constraints for associations, you can disable this feature during initialization:

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DisableForeignKeyConstraintWhenMigrating: true,
})
```

GORM allows you setup FOREIGN KEY constraints's `OnDelete`, `OnUpdate` option with tag `constraint`, for example:

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
