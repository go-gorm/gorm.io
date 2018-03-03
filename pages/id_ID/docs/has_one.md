---
title: Memiliki Satu
layout: page
---
## Has One

A`memiliki satu`asosiasi juga membuat koneksi satu -lawan-satu dengan model lain, tapi dengan beberapa semantik yang berbeda (dan konsekuensinya). Asosiasi ini menunjukkan bahwa setiap contoh dari model mengandung atau memiliki satu contoh model lain.

Sebagai contoh, jika aplikasi anda menyertakan pengguna dan kartu kredit, dan setiap pengguna hanya dapat memiliki satu kartu kredit.

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

Untuk memiliki satu hubungan, Bidang kunci asing harus ada juga, pemilik akan menyimpan primary key dari model itu termasuk ke dalam bidang ini.

Nama bidang biasanya dihasilkan dengan jenis `milik model` ditambah `kunci utama`, untuk contoh di atas adalah `CreditCardID`

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

Secara bawaan, pemilik akan menyimpan `milik model`'s primer menjadi kunci asing, anda bisa mengubah untuk menyimpan bidang lain, seperti penggunaan `Nomor` untuk contoh di bawah ini.

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

Anda dapat menemukan ` memiliki satu` asosiasi dengan `terkait`

```go
var card CreditCard
db.Model(&user).Related(&card, "CreditCard")
//// SELECT * FROM credit_cards WHERE user_id = 123; // 123 is user's primary key
// CreditCard is user's field name, it means get user's CreditCard relations and fill it into variable card
// If the field name is same as the variable's type name, like above example, it could be omitted, like:
db.Model(&user).Related(&card)
```

Untuk penggunaan lanjutan, lihat [Mode Asosiasi](/docs/associations.html#Association-Mode)