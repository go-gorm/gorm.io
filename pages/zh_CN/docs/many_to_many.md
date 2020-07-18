---
title: Many To Many
layout: page
---

## Many To Many

Many to Many 会在两个 model 中添加一张连接表。

例如，您的应用包含了 user 和 language，且一个 user 可以说多种 language，多个 user 也可以说一种 language。

```go
// User 拥有并属于多种 language，`user_languages` 是连接表
type User struct {
  gorm.Model
  Languages []Language `gorm:"many2many:user_languages;"`
}

type Language struct {
  gorm.Model
  Name string
}
```

当使用 GORM 的 `AutoMigrate` 为 `User` 创建表时，GORM 会自动创建连接表

## 反向引用

```go
// User 拥有并属于多种 language，`user_languages` 是连接表
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

## 重写外键

对于 `many2many` 关系，连接表会同时拥有两个模型的外键，例如：

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

若要重写它们，可以使用标签 `foreignKey`、`reference`、`joinforeignKey`、`joinReferences`。当然，您不需要使用全部的标签，你可以仅使用其中的一个重写部分的外键、引用。

```go
type User struct {
    gorm.Model
    Profiles []Profile `gorm:"many2many:user_profiles;foreignKey:Refer;joinForeignKey:UserReferID;References:UserRefer;JoinReferences:ProfileRefer"`
    Refer    uint
}

type Profile struct {
    gorm.Model
    Name      string
    UserRefer uint
}

// Which creates join table: user_profiles
//   foreign key: user_refer_id, reference: users.refer
//   foreign key: profile_refer, reference: profiles.user_refer
```

## 自引用 Many2Many

自引用 many2many 关系

```go
type User struct {
  gorm.Model
    Friends []*User `gorm:"many2many:user_friends"`
}

// Which creates join table: user_friends
//   foreign key: user_id, reference: users.id
//   foreign key: friend_id, reference: users.id
```

## 预加载

GORM allows eager loading has many associations with `Preload`, refer [Preloading (Eager loading)](preload.html) for details

## CRUD with Many2Many

Please checkout [Association Mode](associations.html#Association-Mode) for working with many2many relations

## Customize JoinTable

`JoinTable` can be a full-featured model, like having `Soft Delete`，`Hooks` supports, and define more fields, you can setup it with `SetupJoinTable`, for example:

```go
type Person struct {
  ID        int
  Name      string
  Addresses []Address `gorm:"many2many:person_addresses;"`
}

type Address struct {
  ID   uint
  Name string
}

type PersonAddress struct {
  PersonID  int
  AddressID int
  CreatedAt time.Time
  DeletedAt gorm.DeletedAt
}

func (PersonAddress) BeforeCreate(db *gorm.DB) error {
  // ...
}

// PersonAddress must defined all required foreign keys, or it will raise error
db.SetupJoinTable(&Person{}, "Addresses", &PersonAddress{})
```

## FOREIGN KEY Constraints

You can setup `OnUpdate`, `OnDelete` constraints with tag `constraint`, for example:

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

## Composite Foreign Keys

If you are using [Composite Primary Keys](composite_primary_key.html) for your models, GORM will enable composite foreign keys by default

You are allowed to override the default foreign keys, to specify multiple foreign keys, just separate those keys' name by commas, for example:

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
  SharedTags []Tag `gorm:"many2many:shared_blog_tags;ForeignKey:id;References:id"`
  LocaleTags []Tag `gorm:"many2many:locale_blog_tags;ForeignKey:id,locale;References:id"`
}

// Join Table: blog_tags
//   foreign key: blog_id, reference: blogs.id
//   foreign key: blog_locale, reference: blogs.locale
//   foreign key: tag_id, reference: tags.id
//   foreign key: tag_locale, reference: tags.locale

// Join Table: shared_blog_tags
//   foreign key: blog_id, reference: blogs.id
//   foreign key: tag_id, reference: tags.id

// Join Table: locale_blog_tags
//   foreign key: blog_id, reference: blogs.id
//   foreign key: blog_locale, reference: blogs.locale
//   foreign key: tag_id, reference: tags.id
```

Also check out [Composite Primary Keys](composite_primary_key.html)
