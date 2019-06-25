---
title: Belongs To
layout: page
---

## Belongs To

`belongs to` は、1 対 1 での他 model との関連を、model が他 modelに属する関係として定義します。

アプリケーションに users と profiles があり、ひとつの user にひとつの profile を割り当てることができる場合の例は以下です。

```go
type User struct {
  gorm.Model
  Name string
}

// `Profile` は `User` に属しています, `UserID` は外部キーです
type Profile struct {
  gorm.Model
  UserID int
  User   User
  Name   string
}
```

## Foreign Key

belongs to を定義する場合、外部キーは必ず存在しなければならず、デフォルトの外部キーは所有側の型名と主キーを連結したものになります。

For the above example, to define a model that belongs to `User`, the foreign key should be `UserID`.

GORM provides a way to customize the foreign key, for example:

```go
type User struct {
    gorm.Model
    Name string
}

type Profile struct {
    gorm.Model
  Name      string
  User      User `gorm:"foreignkey:UserRefer"` // use UserRefer as foreign key
  UserRefer uint
}
```

## Association ForeignKey

For a belongs to relationship, GORM usually uses the owner's primary key as the foreign key's value, for above example, it is `User`'s `ID`.

When you assign a profile to a user, GORM will save user's `ID` into profile's `UserID` field.

You are able to change it with tag `association_foreignkey`, e.g:

```go
type User struct {
    gorm.Model
  Refer string
    Name string
}

type Profile struct {
    gorm.Model
  Name      string
  User      User `gorm:"association_foreignkey:Refer"` // use Refer as association foreign key
  UserRefer string
}
```

## Working with Belongs To

You could find `belongs to` associations with `Related`

```go
db.Model(&user).Related(&profile)
//// SELECT * FROM profiles WHERE user_id = 111; // 111 is user's ID
```

For advanced usage, refer [Association Mode](/docs/associations.html#Association-Mode)