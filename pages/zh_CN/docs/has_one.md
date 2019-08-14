---
title: Has One
layout: page
---

## Has One

在一个 `has one` 关联中，其也与另一个 model 建立了一对一关系，但它和一对一关系有不同的语义（及结果）。 Has one 表示：model 的每一个示例都包含或拥有另一个 model 的示例。

例如，你的应用包含了用户和信用卡，并且每个用户只能有一张信用卡。

```go
type User struct {
    gorm.Model
    CreditCard   CreditCard
}

// 用户有一张信用卡，UserID 是外键
type CreditCard struct {
    gorm.Model
    Number   string
    UserID   uint
}
```

## 外键

Foreign Key，在 `has one` 关系中，被拥有 model 必须存在一个外键字段，用于保存所属 model 的主键。

外键字段的名称通常使用 `has one` 拥有者 model 加上它的 `主键` 生成，对于上面的例子，其外键名为 `UserID`.

当你为用户关联信用卡时，信用卡会保存用户的 `ID` 到它的 `UserID` 字段。

如果你想使用另一个字段来记录该关系，您可以通过标签 `foreignkey` 来改变它， 例如：

```go
type User struct {
    gorm.Model
    CreditCard CreditCard `gorm:"foreignkey:UserName"`
}

type CreditCard struct {
    gorm.Model
    Number   string
    UserName string
}
```

## 关联外键

Association ForeignKey，默认情况下，在 `has one` 中，被拥有 model 会使用其外键，保存拥有者 model 的主键，您可以更改保存至另一个字段，例如上面例子中的 `Name`.

```go
type User struct {
    gorm.Model
    Name       `sql:"index"`
    CreditCard CreditCard `gorm:"foreignkey:uid;association_foreignkey:name"`
}

type CreditCard struct {
    gorm.Model
    Number string
    UID    string
}
```

## 多态关联

Polymorphism Association，Gorm 支持 `has many` 和 `has one` 的多态关联。

```go
  type Cat struct {
    ID    int
    Name  string
    Toy   Toy `gorm:"polymorphic:Owner;"`
  }

  type Dog struct {
    ID   int
    Name string
    Toy  Toy `gorm:"polymorphic:Owner;"`
  }

  type Toy struct {
    ID        int
    Name      string
    OwnerID   int
    OwnerType string
  }
```

注意：many-to-many 明确的不支持多态关联，如果使用会抛出错误。

## Has One 的使用

你可以通过 `Related` 使用 `has one` 关联。

```go
var card CreditCard
db.Model(&user).Related(&card, "CreditCard")
//// SELECT * FROM credit_cards WHERE user_id = 123; // 123 is user's primary key
// CreditCard 是 users 的字段，其含义是，获取 user 的 CreditCard 并填充至 card 变量
// 如果字段名与 model 名相同，比如上面的例子，此时字段名可以省略不写，像这样：
db.Model(&user).Related(&card)
```

高级用法请参阅： [关联模式](/docs/associations.html#Association-Mode)