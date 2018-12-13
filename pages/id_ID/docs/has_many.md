---
title: Memiliki Banyak
layout: page
---
## Has Many

`memiliki banyak` asosiasi juga menetapkan satu ke banyak koneksi dengan model lain, tidak seperti ` memiliki satu`, pemilik tersebut dapat memiliki nol atau banyak contoh model.

For example, if your application includes users and credit card, and each user can have many credit cards.

```go
// User has many CreditCards, UserID is the foreign key
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

## Kunci Asing

To define a has many relationship, a foreign key must exists. The default foreign key's name is owner's type name plus its primary key.

Untuk sebuah contoh di atas, untuk menentukan sebuah model yang menjadi milik ` User `, kunci asing seharusnya `UserID `.

Untuk menggunakan bidang lain sebagai kunci asing, anda dapat menyesuaikannya dengan label `foreignkey`, misalnya:

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

GORM biasanya menggunakan kunci utama pemilik sebagai nilai kunci asing, untuk contoh diatas, itu adalah `Pengguna` `ID`,

Saat anda menetapkan kartu kredit ke pengguna, GORM akan menyimpan `ID` pengguna kedalam bidang `UserID` kartu kredit.

Anda dapat mengubahnya dengan label `association_foreignkey`, misalnya:

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

## Asosiasi Polimorfisme

Mendukung polimorfik memiliki banyak dan memiliki satu asosiasi.

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

Anda dapat menemukan `memiliki banyak` asosiasi dengan `Terkait`

```go
db.Model(&user).Related(&emails)
//// SELECT * FROM emails WHERE user_id = 111; // 111 is user's primary key
```

Untuk penggunaan lanjutan, lihat [Mode Asosiasi](/docs/associations.html#Association-Mode)