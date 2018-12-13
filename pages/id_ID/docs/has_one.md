---
title: Memiliki Satu
layout: page
---
## Has One

A`memiliki satu`asosiasi juga membuat koneksi satu -lawan-satu dengan model lain, tapi dengan beberapa semantik yang berbeda (dan konsekuensinya). Asosiasi ini menunjukkan bahwa setiap contoh dari model mengandung atau memiliki satu contoh model lain.

For example, if your application includes users and credit card, and each user can only have one credit card.

```go
// Pengguna memiliki satu KartuKredit, Id Kartu Kredit adalah kunci asing
ketik struct pengguna {
gorm.Model 
KartuKredit KartuKredit
Id KartuKredit uint
}

Ketik struct kartu kredit {
     gorm. Model
     Nomor string
}
```

## Foreign Key

For a has one relationship, a foreign key field must also exist, the owner will save the primary key of the model belongs to it into this field.

The field's name is usually generated with `belongs to model`'s type plus its `primary key`, for the above example it is `CreditCardID`

Saat anda memberikan kartu kredit kepada pengguna, itu akan menyimpan `ID` kartu kredit kedalam bidang `CreditCardID`.

Jika anda ingin menggunakan bidang lain untuk menyimpan hubungan, anda dapat mengubahnya dengan label `foreignkey`, e.g:

```go
type User struct {
  gorm.Model
  CreditCard CreditCard `gorm:"foreignkey:CardRefer"`
  CardRefer uint
}

type CreditCard struct {
    gorm.Model
    Number string
}
```

## Association ForeignKey

By default, the owner will save the `belongs to model`'s primary into a foreign key, you could change to save another field, like use `Number` for below example.

```go
type User struct {
  gorm.Model
  CreditCard CreditCard `gorm:"association_foreignkey:Number"`
  CardRefer uint
}

type CreditCard struct {
    gorm.Model
    Number string
}
```

## Asosiasi Polimorfisme

Supports polymorphic has-many and has-one associations.

```go
  type Cat struct {
    ID    int
    Name  string
    Toy   Toy `gorm:"polymorphic:Owner;"`
  }

  type Dog struct {
    ID   int
    Name string
    Toy  Toy `gorm:"polymorphic:Owner;"`
  }

  type Toy struct {
    ID        int
    Name      string
    OwnerID   int
    OwnerType string
  }
```

Catatan: polimorfik milik-ke dan banyak-ke-banyak secara eksplisit TIDAK didukung, dan akan membuang kesalahan.

## Working with Has One

You could find `has one` associations with `Related`

```go
var card CreditCard
db.Model(&user).Related(&card, "CreditCard")
//// SELECT * FROM credit_cards WHERE user_id = 123; // 123 is user's primary key
// CreditCard is user's field name, it means get user's CreditCard relations and fill it into variable card
// If the field name is same as the variable's type name, like above example, it could be omitted, like:
db.Model(&user).Related(&card)
```

Untuk penggunaan lanjutan, lihat [Mode Asosiasi](/docs/associations.html#Association-Mode)