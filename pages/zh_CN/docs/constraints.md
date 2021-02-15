---
title: 约束
layout: page
---

GORM 允许通过标签创建数据库约束，约束会在通过 GORM 进行 [AutoMigrate 或创建数据表](migration.html)时被创建。

## 检查约束

通过 `check` 标签创建检查约束

```go
type UserIndex struct {
    Name  string `gorm:"check:name_checker,name <> 'jinzhu'"`
    Name2 string `gorm:"check:name <> 'jinzhu'"`
    Name3 string `gorm:"check:,name <> 'jinzhu'"`
}
```

## 索引约束

查看 [数据库索引](indexes.html) 获取详情

## 外键约束

GORM 会为关联创建外键约束，您可以在初始化过程中禁用此功能：

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
