---
title: Many To Many
layout: page
---

## Many To Many

Many to Many では2つのモデル間に結合テーブルを追加します。

例えばユーザと言語について考えると、ユーザは複数の言語を話すことができ、また複数のユーザが特定の言語を話すことができるとした場合、以下のようになります。

```go
// User は複数の言語を所有し、かつ言語に属しています。`user_languages` が結合テーブルになります
type User struct {
  gorm.Model
  Languages []Language `gorm:"many2many:user_languages;"`
}

type Language struct {
  gorm.Model
  Name string
}
```

GORMの `AutoMigrate` を使用して `User` テーブルを作成する場合、GORMは自動的に結合テーブルを作成します。

## 後方参照（Back-Reference）

### Declare
```go
// User は複数の言語を所有し、かつ言語に属しています。`user_languages` が結合テーブルになります
type User struct {
  gorm.Model
  Languages []*Language `gorm:"many2many:user_languages;"`
}

type Language struct {
  gorm.Model
  Name string
  Users []*User `gorm:"many2many:user_languages;"`
}
```

### Retrieve
```go
// Retrieve user list with eager loading languages
func GetAllUsers(db *gorm.DB) ([]User, error) {
    var users []User
    err := db.Model(&User{}).Preload("Languages").Find(&users).Error
    return users, err
}

// Retrieve language list with eager loading users
func GetAllLanguages(db *gorm.DB) ([]Language, error) {
    var languages []Language
    err := db.Model(&Language{}).Preload("Users").Find(&languages).Error
    return languages, err
}
```

## 外部キーのデフォルト設定を上書きする

`many2many` リレーションでは、結合テーブルは2つのモデルを参照する外部キーを持ちます。例：

```go
type User struct {
  gorm.Model
  Languages []Language `gorm:"many2many:user_languages;"`
}

type Language struct {
  gorm.Model
  Name string
}

// Join Table: user_languages
//   foreign key: user_id, reference: users.id
//   foreign key: language_id, reference: languages.id
```

デフォルトの設定を上書くには、`foreignKey`、`references`、`joinForeignKey`、`joinReferences` などのタグを使用します。これらを全て指定する必要はなく、1つのみ使用して外部キー／参照の設定を上書きすることも可能です。

```go
type User struct {
    gorm.Model
    Profiles []Profile `gorm:"many2many:user_profiles;foreignKey:Refer;joinForeignKey:UserReferID;References:UserRefer;joinReferences:ProfileRefer"`
    Refer    uint      `gorm:"index:,unique"`
}

type Profile struct {
    gorm.Model
    Name      string
    UserRefer uint `gorm:"index:,unique"`
}

// Which creates join table: user_profiles
//   foreign key: user_refer_id, reference: users.refer
//   foreign key: profile_refer, reference: profiles.user_refer
```

{% note warn %}
**注意** いくつかのデータベースでは、外部キーが参照するフィールドにユニークインデックスを設定する必要があります。そのため、それらのデータベースでのマイグレーションで外部キーを作成する場合は、`uniqueIndex` タグを指定する必要があります。
{% endnote %}

## Many2Many での自己参照

many2manyリレーションにおける自己参照も可能です。

```go
type User struct {
  gorm.Model
    Friends []*User `gorm:"many2many:user_friends"`
}

// Which creates join table: user_friends
//   foreign key: user_id, reference: users.id
//   foreign key: friend_id, reference: users.id
```

## Eager Loading

GORMでは、 `Preload` を使うことで、many2manyリレーションの Eager Loadingを行うことができます。詳細については [Preload (Eager loading)](preload.html) を参照してください。

## Many2ManyリレーションでのCRUD処理

many2many リレーションを使った処理の詳細については [Association Mode](associations.html#Association-Mode) を参照してください。

## 結合テーブルをカスタマイズする

`JoinTable` can be a full-featured model, like having `Soft Delete`，`Hooks` supports and more fields, you can set it up with `SetupJoinTable`, for example:

{% note warn %}
**注意：** 結合テーブルをカスタマイズする場合、結合テーブルの外部キーを複合主キーにする、あるいは外部キーに複合ユニークインデックスを貼る必要があります。
{% endnote %}

```go
type Person struct {
  ID        int
  Name      string
  Addresses []Address `gorm:"many2many:person_address;"`
}

type Address struct {
  ID   uint
  Name string
}

type PersonAddress struct {
  PersonID  int `gorm:"primaryKey"`
  AddressID int `gorm:"primaryKey"`
  CreatedAt time.Time
  DeletedAt gorm.DeletedAt
}

func (PersonAddress) BeforeCreate(db *gorm.DB) error {
  // ...
}

// Change model Person's field Addresses' join table to PersonAddress
// PersonAddress must defined all required foreign keys or it will raise error
err := db.SetupJoinTable(&Person{}, "Addresses", &PersonAddress{})
```

## 外部キー制約

`constraint` タグを使用することで、 `OnUpdate`, `OnDelete` の制約を掛けることができます。指定した制約はGORMを使ったマイグレーション実行時に作成されます。例：

```go
type User struct {
  gorm.Model
  Languages []Language `gorm:"many2many:user_speaks;"`
}

type Language struct {
  Code string `gorm:"primarykey"`
  Name string
}

// CREATE TABLE `user_speaks` (`user_id` integer,`language_code` text,PRIMARY KEY (`user_id`,`language_code`),CONSTRAINT `fk_user_speaks_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,CONSTRAINT `fk_user_speaks_language` FOREIGN KEY (`language_code`) REFERENCES `languages`(`code`) ON DELETE SET NULL ON UPDATE CASCADE);
```

削除時に `Select` を使用することで、 指定した many2many リレーションも削除することができます。詳細については [Delete with Select](associations.html#delete_with_select) を参照してください。

## 複合外部キー

モデルに [複合主キー](composite_primary_key.html) を定義している場合、GORMはデフォルトで複合外部キーを有効化します。

デフォルトの外部キーを上書いて、複数の外部キーを指定することができます。指定するにはキー名をカンマで区切るだけです。例：

```go
type Tag struct {
  ID     uint   `gorm:"primaryKey"`
  Locale string `gorm:"primaryKey"`
  Value  string
}

type Blog struct {
  ID         uint   `gorm:"primaryKey"`
  Locale     string `gorm:"primaryKey"`
  Subject    string
  Body       string
  Tags       []Tag `gorm:"many2many:blog_tags;"`
  LocaleTags []Tag `gorm:"many2many:locale_blog_tags;ForeignKey:id,locale;References:id"`
  SharedTags []Tag `gorm:"many2many:shared_blog_tags;ForeignKey:id;References:id"`
}

// Join Table: blog_tags
//   foreign key: blog_id, reference: blogs.id
//   foreign key: blog_locale, reference: blogs.locale
//   foreign key: tag_id, reference: tags.id
//   foreign key: tag_locale, reference: tags.locale

// Join Table: locale_blog_tags
//   foreign key: blog_id, reference: blogs.id
//   foreign key: blog_locale, reference: blogs.locale
//   foreign key: tag_id, reference: tags.id

// Join Table: shared_blog_tags
//   foreign key: blog_id, reference: blogs.id
//   foreign key: tag_id, reference: tags.id
```

[複合主キー](composite_primary_key.html) も参照するとよいでしょう。
