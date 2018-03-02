---
title: Milik
layout: halaman
---
## Belongs To

Sebuah `milik asosiasi` membuat koneksi satu-ke-satu dengan model lain, sehingga setiap contoh dari model deklarasi "termasuk" satu contoh dari model lainnya.

Misalnya, jika aplikasi anda menyertakan pengguna dan profil, dan setiap profil dapat diberikan ke satu pengguna saja

```go
type User struct {
  gorm.Model
  Name string
}

// `Profile` belongs to `User`, `UserID` is the foreign key
type Profile struct {
  gorm.Model
  UserID int
  User   User
  Name   string
}
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