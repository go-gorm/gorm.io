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

上述の例では、`User` に属するモデルを定義する場合、外部キーは `UserID` にします。

GORM は外部キーをカスタマイズする手段を提供しています:

```go
type User struct {
  gorm.Model
  Name string
}

type Profile struct {
  gorm.Model
  Name      string
  User      User `gorm:"foreignkey:UserRefer"` // UserRefer を外部キーとして使用する
  UserRefer uint
}
```

## Association ForeignKey

Belongs to を定義する場合、GORMはデフォルトで親モデルの主キーを外部キーとして使用します。 上記の例では`User`の`ID`になります。

ProfileをUserに定義した場合、GORMではUserの`ID`をProfileの`UserID`に保存します。

`association_foreignkey`タグを用いて変更することもできます。

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

`belongs to`の関連は`Related`を使用して取得できます。

```go
db.Model(&user).Related(&profile)
//// SELECT * FROM profiles WHERE user_id = 111; // 111 is user's ID
```

さらに詳しい使い方については [Association Mode](associations.html#Association-Mode) を参照してください。