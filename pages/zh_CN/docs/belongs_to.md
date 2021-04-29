---
title: Belongs To
layout: page
---

## Belongs To

`belongs to` 会与另一个模型建立了一对一的连接。 这种模型的每一个实例都“属于”另一个模型的一个实例。

例如，您的应用包含 user 和 company，并且每个 user 能且只能被分配给一个 company。下面的类型就表示这种关系。 注意，在 `User` 对象中，有一个和 `Company` 一样的 `CompanyID`。 By default, the `CompanyID` is implicitly used to create a foreign key relationship between the `User` and `Company` tables, and thus must be included in the `User` struct in order to fill the `Company` inner struct.

```go
// `User` 属于 `Company`，`CompanyID` 是外键
type User struct {
  gorm.Model
  Name      string
  CompanyID int
  Company   Company
}

type Company struct {
  ID   int
  Name string
}
```

Refer to [Eager Loading](belongs_to.html#Eager-Loading) for details on populating the inner struct.

## 重写外键

要定义一个 belongs to 关系，数据库的表中必须存在外键，默认情况下外键的名字，使用拥有者的名字加上表的主键的字段名字

例如，定义一个User实体属于Company实体，那么外键的名字一般使用CompanyID。

GORM同时提供自定义外键名字的方式，如下例所示。

```go
type User struct {
  gorm.Model
  Name         string
  CompanyRefer int
  Company      Company `gorm:"foreignKey:CompanyRefer"`
  // 使用 CompanyRefer 作为外键
}

type Company struct {
  ID   int
  Name string
}
```

## 重写引用

对于 belongs to 关系，GORM 通常使用数据库表，主表（拥有者）的主键值作为外键参考。 正如上面的例子，我们使用主表Company中的主键字段ID作为外键的参考值。

如果在Company实体中设置了User实体，那么GORM会自动把Company中的ID属性保存到User的CompanyID属性中。

You are able to change it with tag `references`, e.g:

```go
type User struct {
  gorm.Model
  Name      string
  CompanyID string
  Company   Company `gorm:"references:Code"` // 使用 Code 作为引用
}

type Company struct {
  ID   int
  Code string
  Name string
}
```

## Belongs to 的 CRUD

点击 [关联模式](associations.html#Association-Mode) 链接获取 belongs to 相关的用法

## 预加载

GORM允许通过使用`Preload`或者`Joins`来主动加载实体的关联关系，具体内容请参考，[预加载（主动加载）](preload.html)

## 外键约束

你可以通过`OnUpdate`, `OnDelete`配置标签来增加关联关系的级联操作，如下面的例子，通过GORM可以完成用户和公司的级联更新和级联删除操作：

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
