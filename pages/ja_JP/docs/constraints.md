---
title: 制約
layout: page
---

GORMはタグを使用したデータベース制約の作成を可能にします。指定した制約は、 [ GORMによるオートマイグレーション時、テーブル作成時](migration.html) に作成されます

## CHECK制約

CHECK制約の作成は`check`タグで行います。

```go
type UserIndex struct {
    Name  string `gorm:"check:name_checker,name <> 'jinzhu'"`
    Name2 string `gorm:"check:name <> 'jinzhu'"`
    Name3 string `gorm:"check:,name <> 'jinzhu'"`
}
```

## インデックス制約

[Database Indexes](indexes.html)を参照してください。

## 外部キー制約

GORMはアソシエーションのための外部キー制約を作成します。初期化時にこの機能を無効にすることができます：

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DisableForeignKeyConstraintWhenMigrating: true,
})
```

GORMでは、外部キー制約の`OnDelete`と`OnUpdate`オプションを`constraint`タグを用いて設定することができます。例：

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
