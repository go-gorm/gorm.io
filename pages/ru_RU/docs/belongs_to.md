---
title: Belongs To
layout: страница
---
## Belongs To

Связь `принадлежит к "belongs to"` устанавливает связь один к одному с другой моделью, каждый экземпляр текущей модели "принадлежит" экземпляру другой модели.

Для примера, если ваше приложение содержит пользователей и профили, и каждый профиль может быть присвоен одному пользователю

```go
type User struct {
  gorm.Model
  Name string
}

// `Profile` принадлежит к `User`, где `UserID` это внешний ключ
type Profile struct {
  gorm.Model
  UserID int
  User   User
  Name   string
}
```

## Foreign Key

Для определения принадлежности к отношениям, внешний ключ должен существовать, по умолчанию внешний ключ использует имя типа владельца плюс его первичный ключ.

Например, для определения модели, которая принадлежит `User`, внешний ключ должен быть `UserID`.

GORM provides a way to customize the foreign key, for example:

```go
type User struct {
    gorm.Model
    Name string
}

type Profile struct {
    gorm.Model
  Name      string
  User      User `gorm:"foreignkey:UserRefer"` // использовать UserRefer как внешний ключ
  UserRefer string
}
```

## Association ForeignKey

For a belongs to relationship, GORM usually uses the owner's primary key as the foreign key's value, for above example, it is `User`'s `ID`.

Когда вы привязываете профиль к пользователю, GORM сохранит пользовательский `ID` в поле профиля `UserID`.

Вы можете изменить это тэгом `association_foreignkey`, пример:

```go
type User struct {
    gorm.Model
  Refer int
    Name string
}

type Profile struct {
    gorm.Model
  Name      string
  User      User `gorm:"association_foreignkey:Refer"` // использовать Refer как связь внешнего ключа
  UserRefer string
}
```

## Работа с Принадлежит к

You could find `belongs to` associations with `Related`

```go
db.Model(&user).Related(&profile)
//// SELECT * FROM profiles WHERE user_id = 111; // 111 is user's ID
```

Для расширенного использования, смотрите [Режим связей](/docs/associations.html#Association-Mode)