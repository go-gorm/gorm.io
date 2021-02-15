---
title: Belongs To
layout: page
---

## Belongs To

Untuk Belong To sendiri menyiapkan koneksi one to one dengan model lain, sehingga setiap instance dari model yang mendeklarasikan "belong" satu instance dari model lain.

For example, if your application includes users and companies, and each user can be assigned to exactly one company

```go
// `User` belongs to `Company`, `CompanyID` is the foreign key
type User struct {
  gorm.Model
  Name      string
  CompanyID int
  Company   Company
}

type Company struct {
  ID   int
  Name string
}
```

## Override Foreign Key

Nah, agar semua itu memiliki hubungan, tentunya harus di buat kunci (foreign key) sebagai identitas. untuk kunci defaultnya menggunakan nama dari type pemilik di tambah nama bidang kunci utama.

untuk contoh kasus di atas, untuk mendefenisikan  `User` model that belongs to `Company`, the foreign key should be `CompanyID` by convention

GORM sendiri menyediakan cara costumize(mengubah) foreign key, sebagai contoh:

```go
type User struct {
  gorm.Model
  Name         string
  CompanyRefer int
  Company      Company `gorm:"foreignKey:CompanyRefer"`
  // use CompanyRefer as foreign key
}

type Company struct {
  ID   int
  Name string
}
```

## Override References

untuk belong ke relationship , gorm biadanya menggunakan pemilik identitas primary sebagai identitas asing sebagi contoh di atas, ini adalah `Company`'s field `ID`.

saat anda menetapkan pengguna ke conpany, GORM akan menyimpan data  `ID` kedalam pengguna`CompanyID` field.

kamu dapat mengubahnya dengan dengan menggunakan tag `references`, e.g:

```go
type User struct {
  gorm.Model
  Name      string
  CompanyID string
  Company   Company `gorm:"references:Code"` // use Code as references
}

type Company struct {
  ID   int
  Code string
  Name string
}
```

## CRUD with Belongs To

Silahkan periksa [Association Mode](associations.html#Association-Mode) untuk working with belogs to relations

## Eager Loading

Gorm memungkinkan akan memuat untuk asosiasi dengan  `Preload` or `Joins`, refer [Preloading (Eager loading)](preload.html) for details

## FOREIGN KEY Constraints

kamu bisa seting `OnUpdate`, `OnDelete` constraints with tag `constraint`. itu akan di buat pada saat migrasi dengan GORM, sebagi contoh

```go
type User struct {
  gorm.Model
  Name      string
  CompanyID int
  Company   Company `gorm:"constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`
}

type Company struct {
  ID   int
  Name string
}
```
