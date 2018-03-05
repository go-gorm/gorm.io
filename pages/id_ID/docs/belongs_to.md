---
title: Milik
layout: page
---
## Kunci asing

Sebuah `milik asosiasi` membuat koneksi satu-ke-satu dengan model lain, sehingga setiap contoh dari model deklarasi "termasuk" satu contoh dari model lainnya.

Misalnya, jika aplikasi anda menyertakan pengguna dan profil, dan setiap profil dapat diberikan ke satu pengguna saja

```go

Kunci asing
```

## Foreign Key

Untuk menentukan milik hubungan, kunci asing harus ada, kunci asing default menggunakan nama jenis pemilik ditambah kunci utamanya.

Untuk contoh di atas, untuk menentukan model yang dimiliki`Pengguna`, kunci asing seharusnya `Identitas Pengguna`.

GORM menyediakan cara untuk menyesuaikan kunci asing, misalnya:

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

## Kunci Asing Asosiasi

Untuk hubungan, GORM biasanya menggunakan kunci utama pemilik sebagai nilai kunci asing, untuk contoh di atas, itu `Pengguna`'s `ID`.

Ketika anda menetapkan profil untuk pengguna, GORM akan menghemat pengguna `ID` ke profil `Identitas pengguna` bidang.

Anda dapat mengubahnya dengan tanda ` association_foreign_key `, misal:

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

## Bekerja dengan Milik

You could find `belongs to` assciations with `Related`

```go
db.Model(&user).Related(&profile)
//// SELECT * FROM profiles WHERE user_id = 111; // 111 is user's ID
```

For advanced usage, refer [Association Mode](/docs/associations.html#Association-Mode)