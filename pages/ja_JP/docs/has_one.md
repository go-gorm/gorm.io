---
title: Has One
layout: 0x41211f133bb7356c897a279830ef92d2e7711bd2
---
## Имеет один

A `has one` association also sets up a one-to-one connection with another model, but with somewhat different semantics (and consequences). This association indicates that each instance of a model contains or possesses one instance of another model.

For example, if your application includes users and credit card, and each user can only has one credit card.

```go
// User has one CreditCard, CreditCardID is the foreign key
type User struct {
    gorm.Model
    CreditCard   CreditCard
  CreditCardID uint
}

type CreditCard struct {
    gorm.Model
    Number   string
}
```

## Foreign Key

For a has one relationship, a foreign key field must exists also, the owner will saved the primary key of the model belongs to it into this field.

The field's name usually is generated with `belongs to model`'s type plus its `primary key`, for above example, it is `CreditCardID`

When you give a credit card to the user, its will save the credit card's `ID` into its `CreditCardID` field.

If you want to use another field to save the relationship, you can change it with tag `foreignkey`, e.g:

```go
type User struct {
  gorm.Model
  CreditCard CreditCard `gorm:"foreignkey:CardRefer"`
  CardRefer uint
}

type CreditCard struct {
    gorm.Model
    Number string
}
```

## Association ForeignKey

By default, the owner will save the `belogns to model`'s primary into foreign key, you could change to save another field, like use `Number` for below example.

```go
type User struct {
  gorm.Model
  CreditCard CreditCard `gorm:"association_foreignkey:Number"`
  CardRefer uint
}

type CreditCard struct {
    gorm.Model
    Number string
}
```

## Polymorphism Association

Supports polymorphic has-many and has-one associations.

```go
  

```

Note: polymorphic belongs-to and many-to-many are explicitly NOT supported, and will throw errors.

## Working with Has One

You could find `has one` assciations with `Related`

```go
var カード クレジット カード db。モデル (&ユーザー)。(&カードは、「クレジット カード」) を関連///選択 * credit_cards からどこ user_id = 123;123 はユーザーのプライマリ キー//クレジット カードはユーザーのフィールド名、ユーザーのクレジット カード関係を取得し、変数のカードにそれを埋めるという//フィールド名は、変数の型名と同じように上記の例では、これは省略できますが場合のような: db。モデル (&ユーザー)。(&カード) を関連
```

For advanced usage, refer [Association Mode](/docs/associations.html#Association-Mode)