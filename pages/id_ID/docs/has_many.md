---
title: Has Many
layout: page
---
## Has Many

A `has many` association also sets up a one-to-many connection with another model, unlike `has one`, the owner could have zero or many instances of models.

Misalnya, jika aplikasi anda menyertakan pengguna dan kartu kredit, dan setiap pengguna dapat memiliki banyak kartu kredit.

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

## Foreign Key

Untuk menentukan memiliki banyak hubungan, kunci asing harus ada, nama kunci asing default adalah nama tipe pemilik ditambah kunci utamanya.

For a above example, to define a model that belongs to `User`, the foreign key should be `UserID`.

Untuk menggunakan bidang lain sebagai kunci tamu, anda dapat mengkustomisasinya dengan label `foreignkey`, misalnya:

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

GORM biasanya menggunakan kunci primer pemilik sebagai nilai kunci tamu, untuk contoh diatas, itu adalah `User` `ID`,

When you assign credit cards to a user, GORM will save user's `ID` into credit cards' `UserID` field.

Anda dapat mengubahnya dengan label `association_foreignkey`, misalnya:

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

Catatan: polimorfik milik-ke dan banyak-ke-banyak secara eksplisit TIDAK didukung, dan akan membuang kesalahan.

## Bekerja dengan Memiliki Banyak

You could find `has many` assciations with `Related`

```go
db.Model(&user).Related(&emails)
//// SELECT * FROM emails WHERE user_id = 111; // 111 is user's primary key
```

For advanced usage, refer [Association Mode](/docs/associations.html#Association-Mode)