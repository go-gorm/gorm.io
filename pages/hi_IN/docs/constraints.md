---
title: Constraints
layout: पृष्ठ
---

GORM टैग के साथ डेटाबेस कंस्ट्रेंट बनाने की अनुमति देता है, [GORM के साथ AutoMigrate या CreateTable](migration.html) होने पर कंस्ट्रेंट बनाए जाएंगे

## CHECK Constraint

`check` टैग के साथ CHECK कंस्ट्रेंट बनाएं

```go
type UserIndex struct {
    Name  string `gorm:"check:name_checker,name <> 'jinzhu'"`
    Name2 string `gorm:"check:name <> 'jinzhu'"`
    Name3 string `gorm:"check:,name <> 'jinzhu'"`
}
```

## Index Constraint

चेकआउट [डेटाबेस इंडेक्स](indexes.html)

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
