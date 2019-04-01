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

GORM provides a way to customize the foreign key, for example:

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

For a belongs to relationship, GORM usually uses the owner's primary key as the foreign key's value, for above example, it is `User`'s `ID`.

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

You could find `belongs to` associations with `Related`

```go
db.Model(&user).Related(&profile)
//// SELECT * FROM profiles WHERE user_id = 111; // 111 is user's ID
```

For advanced usage, refer [Association Mode](/docs/associations.html#Association-Mode)