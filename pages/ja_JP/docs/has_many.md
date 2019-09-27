---
title: Has Many
layout: page
---

## Has Many

`has many`アソシエーションは他のモデルとのone-to-manyなつながりを表します。`has one`とは異なり、親は0もしくは多のモデルのインスタンスを持ちます。

例えば、あなたのアプリケーションにおいて、userとcredit cardモデルがあり、それぞれのuserがたくさんのcredit cardを所有していたとします。

```go
// User has many CreditCards, UserID is the foreign key
type User struct {
    gorm.Model
    CreditCards []CreditCard
}

type CreditCard struct {
    gorm.Model
    Number   string
    UserID  uint
}
```

## Foreign Key

has manyの関係を定義する場合、外部キーが必ず存在します。デフォルトの外部キーの名前は、参照されるモデルの名前と主キーの名前を結合したものになります(例えば、UserIDやCardIDなど)。

上述の例では、`User` に属するモデルを定義する場合、外部キーは `UserID` にします。

外部キーとして他のフィールドを使う場合、`foreignkey`タグを使用してカスタマイズすることができる。たとえば、

```go
type User struct {
    gorm.Model
    CreditCards []CreditCard `gorm:"foreignkey:UserRefer"`
}

type CreditCard struct {
    gorm.Model
    Number    string
  UserRefer uint
}
```

## Association ForeignKey

GORM usually uses the owner's primary key as the foreign key's value, for above example, it is the `User`'s `ID`,

When you assign credit cards to a user, GORM will save the user's `ID` into credit cards' `UserID` field.

You are able to change it with tag `association_foreignkey`, e.g:

```go
type User struct {
    gorm.Model
  MemberNumber string
    CreditCards  []CreditCard `gorm:"foreignkey:UserMemberNumber;association_foreignkey:MemberNumber"`
}

type CreditCard struct {
    gorm.Model
    Number           string
  UserMemberNumber string
}
```

## Polymorphism Association

GORM supports polymorphic has-many and has-one associations.

```go
  type Cat struct {
    ID    int
    Name  string
    Toy   []Toy `gorm:"polymorphic:Owner;"`
  }

  type Dog struct {
    ID   int
    Name string
    Toy  []Toy `gorm:"polymorphic:Owner;"`
  }

  type Toy struct {
    ID        int
    Name      string
    OwnerID   int
    OwnerType string
  }
```

Note: polymorphic belongs-to and many-to-many are explicitly NOT supported, and will throw errors.

## Working with Has Many

You could find `has many` associations with `Related`

```go
db.Model(&user).Related(&emails)
//// SELECT * FROM emails WHERE user_id = 111; // 111 is user's primary key
```

For advanced usage, refer to [Association Mode](/docs/associations.html#Association-Mode)