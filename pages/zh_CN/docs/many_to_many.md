---
title: Many To Many
layout: page
---

## Many To Many

Many to Many 在两个 model 中添加一张连接表。

比如，您的应用程序包含用户和语言，一个用户可以说多种语言，多个用户也可以说某一种语言。

```go
// 用户拥有且属于多种语言，使用 `user_languages` 作为连接表
type User struct {
    gorm.Model
    Languages         []Language `gorm:"many2many:user_languages;"`
}

type Language struct {
    gorm.Model
    Name string
}
```

## 互引用关联

```go
// Back-Reference，用户拥有且属于多种语言，使用 `user_languages` 作为连接表
type User struct {
    gorm.Model
    Languages         []*Language `gorm:"many2many:user_languages;"`
}

type Language struct {
    gorm.Model
    Name string
    Users             []*User     `gorm:"many2many:user_languages;"`
}

var users []User
language := Language{}

db.First(&language, "id = ?", 111)

db.Model(&language).Related(&users,  "Users")
//// SELECT * FROM "users" INNER JOIN "user_languages" ON "user_languages"."user_id" = "users"."id" WHERE  ("user_languages"."language_id" IN ('111'))
```

## 多外键

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

Foreign Keys，它将为这两个 struct 创建多对多关系，并且他们的关系将被保存到连接表 `PersonAccount` ，连接表的外键为 `customize_person_id_person` 和 `customize_account_id_account`.

## 连接表外键

Jointable ForeignKey，如果你想改变连接表的外键，你可以使用标签 `association_jointable_foreignkey` 和 `jointable_foreignkey`.

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

## 自引用关联

Self-Referencing，在自引用的多对多关系中，你必须在连接表中修改关联外键。

使用属性名及其主键生成关联外键，使得关联外键与外键不同，比如：

```go
type User struct {
  gorm.Model
  Friends []*User `gorm:"many2many:friendships;association_jointable_foreignkey:friend_id"`
}
```

GORM 会生成一个关联表，其外键为 `user_id` 和 `friend_id`，并用其保存自引用用户关系。

然后你还是可以像正常关系一样操作它们，比如：

```go
DB.Preload("Friends").First(&user, "id = ?", 1)

DB.Model(&user).Association("Friends").Append(&User{Name: "friend1"}, &User{Name: "friend2"})

DB.Model(&user).Association("Friends").Delete(&User{Name: "friend2"})

DB.Model(&user).Association("Friends").Replace(&User{Name: "new friend"})

DB.Model(&user).Association("Friends").Clear()

DB.Model(&user).Association("Friends").Count()
```

## Many To Many 的使用

```go
db.Model(&user).Related(&languages, "Languages")
//// SELECT * FROM "languages" INNER JOIN "user_languages" ON "user_languages"."language_id" = "languages"."id" WHERE "user_languages"."user_id" = 111

// 查询 user 时会预加载 Languages
db.Preload("Languages").First(&user)
```

高级用法请参阅： [关联模式](/docs/associations.html#Association-Mode)