---
title: Many To Many
layout: page
---

## Many To Many

Many to Many adds a join table between two models.

Misalnya, jika aplikasi anda mencakup pengguna dan bahasa, dan pengguna dapat berbicara banyak bahasa, dan banyak pengguna dapat mengucapkan bahasa tertentu.

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

## Kunci asing

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

It will create a many2many relationship for those two structs, and their relations will be saved into join table `PersonAccount` with foreign keys `customize_person_id_person` AND `customize_account_id_account`

## Jointable ForeignKey

If you want to change join table's foreign keys, you could use tag `association_jointable_foreignkey`, `jointable_foreignkey`

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

## Referensi-Diri

Untuk menentukan referensi-diri banyak2banyak hubungan, Anda harus mengubah kunci asing asosiasi di tabel bergabung.

untuk membuatnya berbeda dengan kunci asing sumber ini, yang dihasilkan menggunakan nama struct dan kunci utama, misalnya:

```go
type User struct {
  gorm.Model
  Friends []*User `gorm:"many2many:friendships;association_jointable_foreignkey:friend_id"`
}
```

GORM will create a join table with foreign key `user_id` and `friend_id`, and use it to save user's self-reference relationship.

Kemudian anda dapat mengoperasikannya seperti hubungan normal, misalnya:

```go
DB.Preload("Friends").First(&user, "id = ?", 1)

DB.Model(&user).Association("Friends").Append(&User{Name: "friend1"}, &User{Name: "friend2"})

DB.Model(&user).Association("Friends").Delete(&User{Name: "friend2"})

DB.Model(&user).Association("Friends").Replace(&User{Name: "new friend"})

DB.Model(&user).Association("Friends").Clear()

DB.Model(&user).Association("Friends").Count()
```

## Bekerja dengan Banyak Untuk Banyak

```go
db.Model(&user).Related(&languages, "Languages")
//// SELECT * FROM "languages" INNER JOIN "user_languages" ON "user_languages"."language_id" = "languages"."id" WHERE "user_languages"."user_id" = 111

// Preload Languages when query user
db.Preload("Languages").First(&user)
```

For advanced usage, refer [Association Mode](associations.html#Association-Mode)