---
title: Many To Many (многие ко многим)
layout: страница
---

## Many To Many (многие ко многим)

Many to Many добавляет объединяющую таблицу между двумя моделями.

Например, если ваше приложение включает пользователей и языки, и пользователь может говорить на многих языках, и многие пользователи могут говорить на определенном языке.

```go
// Пользователь имеет и принадлежит многим языкам, `user_languages` объединяющую таблица
type User struct {
  gorm.Model
  Languages []Language `gorm:"many2many:user_languages;"`
}

type Language struct {
  gorm.Model
  Name string
}
```

При использовании GORM `AutoMigrate` для создания таблицы по модели `User`, GORM автоматически создаст таблицу объединения

## Обратная ссылка

### Declare
```go
// Пользователь имеет и принадлежит ко многим языкам, используется `user_languages` как таблица связей
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

## Переопределить внешний ключ

Для `many2many` связей, объединяющая таблица имеет внешний ключ, который ссылается на две модели, например:

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

Чтобы перезаписать их, вы можете использовать тэг `foreignKey`, `references`, `joinForeignKey`, `joinReferences`, необязательно использовать их вместе, вы можете просто использовать один из них, чтобы перезаписать внешние ключи

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
**ПРИМЕЧАНИЕ:** Некоторые базы данных позволяют создавать только внешние ключи базы данных, которые ссылаются на поле, имеющее уникальный индекс, поэтому вам необходимо указать тег `unique index`, если вы создаете внешние ключи базы данных при миграции
{% endnote %}

## Самосвязанный Many2Many

Самосвязанные отношения «многие-многие»

```go
type User struct {
  gorm.Model
    Friends []*User `gorm:"many2many:user_friends"`
}

// Which creates join table: user_friends
//   foreign key: user_id, reference: users.id
//   foreign key: friend_id, reference: users.id
```

## Нетерпеливая загрузка

GORM allows eager loading has many associations with `Preload`, refer [Preloading (Eager loading)](preload.html) for details

## CRUD с Many2Many

Please checkout [Association Mode](associations.html#Association-Mode) for working with many2many relations

## Настроить таблицу связей

`JoinTable` can be a full-featured model, like having `Soft Delete`，`Hooks` supports and more fields, you can setup it with `SetupJoinTable`, for example:

{% note warn %}
**NOTE:** Customized join table's foreign keys required to be composited primary keys or composited unique index
{% endnote %}

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

## Ограничения внешних ключей

You can setup `OnUpdate`, `OnDelete` constraints with tag `constraint`, it will be created when migrating with GORM, for example:

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

You are also allowed to delete selected many2many relations with `Select` when deleting, checkout [Delete with Select](associations.html#delete_with_select) for details

## Композитные внешние ключи

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

Also check out [Composite Primary Keys](composite_primary_key.html)
