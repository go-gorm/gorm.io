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

## Fremdschlüssel

Um eine zu einer Beziehung gehörende Eigenschaft zu definieren, muss der Fremdschlüssel vorhanden sein. Der Standard-Fremdschlüssel verwendet den Typnamen des Eigentümers und seinen Primärschlüssel.

Um beispielsweise ein Modell zu definieren, das zu ` User ` gehört, sollte der Fremdschlüssel ` UserID ` lauten.

GORM provides a way to customize the foreign key, for example:

```go
type User struct {
    gorm.Model
    Name string
}

type Profile struct {
    gorm.Model
  Name      string
  User      User `gorm:"foreignkey:UserRefer"` // benutze UserRefer als Fremdschlüssel
  UserRefer string
}
```

## Assoziations-Fremdschlüssel

For a belongs to relationship, GORM usually uses the owner's primary key as the foreign key's value, for above example, it is `User`'s `ID`.

Wenn man einem Benutzer ein Profil zuweist, speichert GORM die `ID` des Benutzers im Feld `UserID` des Profils.

Man kann es mit dem Tag `association_foreignkey` ändern, e.g:

```go
type User struct {
    gorm.Model
  Refer int
    Name string
}

type Profile struct {
    gorm.Model
  Name      string
  User      User `gorm:"association_foreignkey:Refer"` // benutze Refer als Fremdschlüssel der Assoziation
  UserRefer string
}
```

## Arbeiten mit Belongs To

You could find `belongs to` associations with `Related`

```go
db.Model(&user).Related(&profile)
//// SELECT * FROM profiles WHERE user_id = 111; // 111 ist die ID des Nutzers
```

Für erweiterte Verwendung verweisen wir auf den [Assoziationsmodus](/docs/associations.html#Association-Mode)