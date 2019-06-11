---
title: Has Many
layout: страница
---

## Has Many

Связь `has many` устанавливают соединение один ко многим с другой моделью, в отличие от `has one`, владелец может иметь нулевую или много экземпляров моделей.

Например, если ваше приложение включает в себя пользователей и кредитную карту, и каждый пользователь может иметь много кредитных карт.

```go
// Пользователи имеют много кредитных карт, UserID является внешним ключом
type User struct {
    gorm.Model
    CreditCards []CreditCard
}

type CreditCard struct {
    gorm.Model
    Number   string
    UserID  uint
}
```

## Foreign Key

Для определения связи has many, должен существовать внешний ключ. Имя внешнего ключа по умолчанию является именем владельца, плюс имя основного ключа (например, UserID, CardID и т.д.).

Например, для определения модели, которая принадлежит `User`, внешний ключ должен быть `UserID`.

Чтобы использовать другое поле как внешний ключ, вы можете настроить его с помощью `foreignkey` тега, например:

```go
type User struct {
    gorm.Model
    CreditCards []CreditCard `gorm:"foreignkey:UserRefer"`
}

type CreditCard struct {
    gorm.Model
    Number    string
  UserRefer uint
}
```

## Association ForeignKey

Для принадлежности к отношениям, GORM обычно использует первичный ключ владельца как значение внешнего ключа, например, модель `User` с полем `ID`,

Когда вы привязываете кредитную карту к пользователю, GORM сохранит пользовательский `ID` в поле кредитных карт `UserID`.

Вы можете изменить это тэгом `association_foreignkey`, пример:

```go
type User struct {
    gorm.Model
  MemberNumber string
    CreditCards  []CreditCard `gorm:"foreignkey:UserMemberNumber;association_foreignkey:MemberNumber"`
}

type CreditCard struct {
    gorm.Model
    Number           string
  UserMemberNumber string
}
```

## Polymorphism Association

GORM поддерживает полиморфический has-many "имеет много" и has-one "имеет одно" объединение.

```go
  type Cat struct {
    ID    int
    Name  string
    Toy   []Toy `gorm:"polymorphic:Owner;"`
  }

  type Dog struct {
    ID   int
    Name string
    Toy  []Toy `gorm:"polymorphic:Owner;"`
  }

  type Toy struct {
    ID        int
    Name      string
    OwnerID   int
    OwnerType string
  }
```

Примечание: полиморфический belongs-to "принадлежит к" и many-to-many "многие ко многим" не поддерживаются, и будут выводить ошибки.

## Работа с Has Many

You could find `has many` associations with `Related`

```go
db.Model(&user).Related(&emails)
//// SELECT * FROM emails WHERE user_id = 111; // 111 is user's primary key
```

Для расширенного использования, смотрите [Режим связей](/docs/associations.html#Association-Mode)
