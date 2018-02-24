---
title: Belongs To
layout: page
---
## Belongs To

Eine `belongs to` Assoziation stellt eine Eins-zu-Eins-Verbindung mit einem anderen Modell her, so dass jede Instanz des Deklarationsmodells zu einer Instanz des anderen Modells "gehört".

Zum Beispiel, wenn eine Anwendung Benutzer und Profile enthält und jedes Profil genau einem Benutzer zugewiesen werden kann

```go
type User struct {
  gorm.Model
  Name string
}

// `Profile` gehört zu `User`, `UserID` ist der Fremdschlüssel
type Profile struct {
  gorm.Model
  UserID int
  User   User
  Name   string
}
```

## Foreign Key

To define a belongs to relationship, the foreign key must exists, default foreign key uses owner's type name plus its primary key.

For a above example, to define a model that belongs to `User`, the foreign key should be `UserID`.

GORM provides a way to customzie the foreign key, for example:

```go
type User struct {
    gorm.Model
    Name string
}

type Profile struct {
    gorm.Model
  Name      string
  User      User `gorm:"foreignkey:UserRefer"` // use UserRefer as foreign key
  UserRefer string
}
```

## Association ForeignKey

For a belongs to relationship, GORM usually use owner's primary key as the foreign key's value, for above example, it is `User`'s `ID`.

When you assign a profile to a user, GORM will save user's `ID` into profile's `UserID` field.

You are able to change it with tag `association_foreignkey`, e.g:

```go
type User struct {
    gorm.Model
  Refer int
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

You could find `belongs to` assciations with `Related`

```go
db.Model(&user).Related(&profile)
//// SELECT * FROM profiles WHERE user_id = 111; // 111 is user's ID
```

For advanced usage, refer [Association Mode](/docs/associations.html#Association-Mode)