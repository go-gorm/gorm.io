---
title: Has Many
layout: seite
---
## Has Many

A `has many` association also sets up a one-to-many connection with another model, unlike `has one`, the owner could have zero or many instances of models.

For example, if your application includes users and credit card, and each user can has many credit cards.

```go
// User has many emails, UserID is the foreign key
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

## Fremdschlüssel

Um eine zu einer Beziehung gehörende Eigenschaft zu definieren, muss der Fremdschlüssel vorhanden sein. Der Standard-Fremdschlüssel verwendet den Typnamen des Eigentümers und seinen Primärschlüssel.

Um beispielsweise ein Modell zu definieren, das zu ` User ` gehört, sollte der Fremdschlüssel ` UserID ` lauten.

To use another field as foreign key, you can customize it with tag `foreignkey`, e.g:

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

## Assoziations-Fremdschlüssel

Bei einer `belongs to` Beziehung verwendet GORM normalerweise den Primärschlüssel des Eigentümers als Wert des Fremdschlüssels, im obigen Beispiel `User`'s `ID`,

Wenn man einem Benutzer ein Profil zuweist, speichert GORM die `ID` des Benutzers im Feld `UserID` des Profils.

Man kann es mit dem Tag `association_foreignkey` ändern, e.g:

```go
type User struct {
    gorm.Model
  MemberNumber string
    CreditCards  []CreditCard `gorm:"foreignkey:UserMemberNumber,association_foreignkey:MemberNumber"`
}

type CreditCard struct {
    gorm.Model
    Number           string
  UserMemberNumber string
}
```

## Polymorphism Association

Supports polymorphic has-many and has-one associations.

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

Note: polymorphic belongs-to and many-to-many are explicitly NOT supported, and will throw errors.

## Working with Has Many

Man kann `belongs to` Assoziationen mit `Related` finden

```go
db.Model(&user).Related(&profile)
//// SELECT * FROM profiles WHERE user_id = 111; // 111 ist die ID des Nutzers
```

Für erweiterte Verwendung verweisen wir auf den [Assoziationsmodus](/docs/associations.html#Association-Mode)