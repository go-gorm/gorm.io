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

// Таблица связей: user_languages
//   внешний ключ: user_id, ссылается на: users.id
//   внешний ключ: language_id, ссылается на: languages.id
```

Чтобы переопределить их, вы можете использовать теги `foreignKey`, `reference`, `joinForeignKey`, `joinReferences`, не обязательно использовать их вместе, вы можете просто использовать один из них для переопределения некоторых внешних ключей/ссылок

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

// Который создает таблицу связей: user_profiles
//   внешний ключ: user_refer_id, ссылается на: users.refer
//   внешний ключ: profile_refer, ссылается на: profiles.user_refer
```

## Самосвязанный Many2Many

Самосвязанная связь Many2Many

```go
type User struct {
  gorm.Model
    Friends []*User `gorm:"many2many:user_friends"`
}

// Который создает таблицу связей: user_friends
//   внешний ключ: user_id, ссылается на: users.id
//   внешний ключ: friend_id, ссылается на: users.id
```

## Нетерпеливая загрузка

GORM позволяет использовать нетерпеливую загрузку для связей has many (имеет много) с помощью `Preload`, смотрите [Предзагрузка (Нетерпеливая загрузка)](preload.html) для подробностей

## CRUD с Many2Many

Пожалуйста, смотрите [режим связей](associations.html#Association-Mode) для работы с many2many связями

## Настроить таблицу связей

`Таблица связей` может быть полнофункциональной моделью, например `Soft Delete`,`Хуки` поддерживают и определяют больше полей, вы можете настроить его при помощи `SetupJoinTable`, например:

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

// в PersonAddress должны быть определены все необходимые внешние ключи, или выкинет ошибку
db.SetupJoinTable(&Person{}, "Addresses", &PersonAddress{})
```

## Ограничения внешних ключей

Вы можете настроить `OnUpdate`, `OnDelete` ограничения с помощью тега `constraint`, например:

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

## Композитные внешние ключи

При использовании [Композитных первичных ключей](composite_primary_key.html) для моделей, GORM по умолчанию включит композитные внешние ключи

Вам разрешено переопределить внешние ключи по умолчанию, для указания нескольких внешних ключей, просто разделите их имя запятыми, например:

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

// таблица связей: blog_tags
//   внешний ключ: blog_id, ссылается на: blogs.id
//   внешний ключ: blog_locale, ссылается на: blogs.locale
//   внешний ключ: tag_id, ссылается на: tags.id
//   внешний ключ: tag_locale, ссылается на: tags.locale

// таблица связей: shared_blog_tags
//   внешний ключ: blog_id, ссылается на: blogs.id
//   внешний ключ: tag_id, ссылается на: tags.id

// таблица связей: locale_blog_tags
//   внешний ключ: blog_id, ссылается на: blogs.id
//   внешний ключ: blog_locale, ссылается на: blogs.locale
//   внешний ключ: tag_id, ссылается на: tags.id
```

Также смотрите [Композитный первичный Ключ](composite_primary_key.html)
