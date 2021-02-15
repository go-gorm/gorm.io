---
title: Constraints
layout: page
---

GORMはタグを使用したデータベース制約の作成を可能にします。 [GORMによるオートマイグレーション時、たテーブル作成時](migration.html)に制約が作成されます

## CHECK Constraint

CHECK制約の作成は`check`タグで行います。

```go
type UserIndex struct {
    Name  string `gorm:"check:name_checker,name <> 'jinzhu'"`
    Name2 string `gorm:"check:name <> 'jinzhu'"`
    Name3 string `gorm:"check:,name <> 'jinzhu'"`
}
```

## Index Constraint

[Database Indexes](indexes.html)を参照してください。

## Foreign Key Constraint

GORMはアソシエーションのための外部キー制約を作成します。初期化時にこの機能を無効にすることができます：

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
