---
title: Many To Many
layout: страница
---

## Many To Many

Многие ко многим добавляет join таблицы между двумя моделями.

For example, if your application includes users and languages, and a user can speak many languages, and many users can speak a specified language.

```go
// User has and belongs to many languages, use `user_languages` as join table
type User struct {
  gorm.Model
  Languages         []Language `gorm:"many2many:user_languages;"`
}

type Language struct {
  gorm.Model
  Name string
}
```

## Back-Reference

```go
// User has and belongs to many languages, use `user_languages` as join table
type User struct {
  gorm.Model
  Languages         []*Language `gorm:"many2many:user_languages;"`
}

type Language struct {
  gorm.Model
  Name string
  Users               []*User     `gorm:"many2many:user_languages;"`
}

var users []User
language := Language{}

db.First(&language, "id = ?", 111)

db.Model(&language).Related(&users,  "Users")
//// SELECT * FROM "users" INNER JOIN "user_languages" ON "user_languages"."user_id" = "users"."id" WHERE  ("user_languages"."language_id" IN ('111'))
```

## Foreign Keys

```go
type CustomizePerson struct {
  IdPerson string             `gorm:"primary_key:true"`
  Accounts []CustomizeAccount `gorm:"many2many:PersonAccount;association_foreignkey:idAccount;foreignkey:idPerson"`
}

type CustomizeAccount struct {
  IdAccount string `gorm:"primary_key:true"`
  Name      string
}
```

Он создаст многие ко многим отношение для этих двух структур, и их отношения будут сохранены в таблицу для присоединения `PersonAccount` с внешним ключом `customize_person_id_person` И `customize_account_id_account`

## Jointable ForeignKey

Если вы хотите изменить внешние ключи таблицы присоединения, вы можете использовать тег `association_jointable_foreignkey`, `jointable_foreignkey`

```go
type CustomizePerson struct {
  IdPerson string             `gorm:"primary_key:true"`
  Accounts []CustomizeAccount `gorm:"many2many:PersonAccount;foreignkey:idPerson;association_foreignkey:idAccount;association_jointable_foreignkey:account_id;jointable_foreignkey:person_id;"`
}

type CustomizeAccount struct {
  IdAccount string `gorm:"primary_key:true"`
  Name      string
}
```

## Self-Referencing

Чтобы определить само ссылающиеся отношения многие ко многим, вы должны изменить внешний ключ ассоциации в таблице присоединяющихся.

чтобы сделать его отличным от внешнего ключа источника, который генерируется с использованием имени struct и его основного ключа, например:

```go
type User struct {
  gorm.Model
  Friends []*User `gorm:"many2many:friendships;association_jointable_foreignkey:friend_id"`
}
```

GORM создаст таблицу для присоединения с внешним ключом `user_id` и `friend_id`, и использует ее для сохранения само ссылки таблицы пользователя.

Затем вы можете работать как с обычными отношениями, например:

```go
DB.Preload("Friends").First(&user, "id = ?", 1)

DB.Model(&user).Association("Friends").Append(&User{Name: "friend1"}, &User{Name: "friend2"})

DB.Model(&user).Association("Friends").Delete(&User{Name: "friend2"})

DB.Model(&user).Association("Friends").Replace(&User{Name: "new friend"})

DB.Model(&user).Association("Friends").Clear()

DB.Model(&user).Association("Friends").Count()
```

## Работа с Many To Many

```go
db.Model(&user).Related(&languages, "Languages")
//// SELECT * FROM "languages" INNER JOIN "user_languages" ON "user_languages"."language_id" = "languages"."id" WHERE "user_languages"."user_id" = 111

// Предварительно загрузить Languages при запросе user
db.Preload("Languages").First(&user)
```

For advanced usage, refer [Association Mode](associations.html#Association-Mode)