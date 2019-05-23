---
title: Asosiasi
layout: page
---

## Buat/Perbarui Otomatis

GORM akan menyimpan otomatis asosiasi dan referensi saat membuat / memperbarui rekama. Jika asosiasi memiliki kunci utama, GORM akan memanggil ` Perbarui ` untuk menyimpannya, jika tidak maka akan dibuat.

```go
user := User{
    Name:            "jinzhu",
    BillingAddress:  Address{Address1: "Billing Address - Address 1"},
    ShippingAddress: Address{Address1: "Shipping Address - Address 1"},
    Emails:          []Email{
        {Email: "jinzhu@example.com"},
        {Email: "jinzhu-2@example.com"},
    },
    Languages:       []Language{
        {Name: "ZH"},
        {Name: "EN"},
    },
}

db.Create(&user)
//// BEGIN TRANSACTION;
//// INSERT INTO "addresses" (address1) VALUES ("Billing Address - Address 1");
//// INSERT INTO "addresses" (address1) VALUES ("Shipping Address - Address 1");
//// INSERT INTO "users" (name,billing_address_id,shipping_address_id) VALUES ("jinzhu", 1, 2);
//// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu@example.com");
//// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu-2@example.com");
//// INSERT INTO "languages" ("name") VALUES ('ZH');
//// INSERT INTO user_languages ("user_id","language_id") VALUES (111, 1);
//// INSERT INTO "languages" ("name") VALUES ('EN');
//// INSERT INTO user_languages ("user_id","language_id") VALUES (111, 2);
//// COMMIT;

db.Save(&user)
```

## Lewati AutoUpdate

Jika asosiasi anda telah ada di basis data, anda mungkin tidak ingin memperbaruinya.

Anda dapat menggunakan pengaturan DB, atur `gorm:association_autoupdate` ke `false`

```go
// Don't update associations having primary key, but will save reference
db.Set("gorm:association_autoupdate", false).Create(&user)
db.Set("gorm:association_autoupdate", false).Save(&user)
```

or use GORM tags, `gorm:"association_autoupdate:false"`

```go
type User struct {
  gorm.Model
  Name       string
  CompanyID  uint
  // Don't update associations having primary key, but will save reference
  Company    Company `gorm:"association_autoupdate:false"`
}
```

## Lewati AutoUpdate

Meskipun Anda menonaktifkan `MemperbaruiOtomatis `, asosiasi w / o kunci utama masih harus dibuat dan referensi akan disimpan.

Untuk menonaktifkan ini, anda dapat mengatur pengaturan DB `gorm:association_autocreate` ke `false`

```go
// Don't create associations w/o primary key, WON'T save its reference
db.Set("gorm:association_autocreate", false).Create(&user)
db.Set("gorm:association_autocreate", false).Save(&user)
```

atau gunakan label GORM, `gorm:"association_autocreate:false"`

    type User struct {
      gorm.Model
      Name       string
      // Don't create associations w/o primary key, WON'T save its reference
      Company1   Company `gorm:"association_autocreate:false"`
    }
    

## Lewati buat mobil /perbaharui

Untuk menonaktifkan `` Buat Otomotis </ code> dan <code> Buat Perbaharui </ code>, Anda dapat menggunakan kedua pengaturan tersebut bersama-sama</p>

<pre><code class="go">db.Set("gorm:association_autoupdate", false).Set("gorm:association_autocreate", false).Create(&user)

type User struct {
  gorm.Model
  Name    string
  Company Company `gorm:"association_autoupdate:false;association_autocreate:false"`
}
``</pre> 

Atau gunakan `gorm:save_associations`

    db.Set("gorm:save_associations", false).Create(&user)
    db.Set("gorm:save_associations", false).Save(&user)
    
    type User struct {
      gorm.Model
      Name    string
      Company Company `gorm:"save_associations:false"`
    }
    

## Lewati Penyimpanan Referensi

Jika anda bahkan tidak ingin menyimpan referensi asosiasi ketika memperbarui / menyimpan data, anda bisa menggunakan trik di bawah ini

```go
db.Set("gorm:association_save_reference", false).Save(&user)
db.Set("gorm:association_save_reference", false).Create(&user)
```

atau gunakan tanda

```go
type User struct {
  gorm.Model
  Name       string
  CompanyID  uint
  Company    Company `gorm:"association_save_reference:false"`
}
```

## Mode Asosiasi

Asosiasi motede berisi beberapa metode penolong untuk menangani hal-hal yang berhubungan dengan hubungan dengan mudah.

```go
// Start Association Mode
var user User
db.Model(&user).Association("Languages")
// `user` is the source, must contains primary key
// `Languages` is source's field name for a relationship
// AssociationMode can only works if above two conditions both matched, check it ok or not:
// db.Model(&user).Association("Languages").Error
```

### Temukan Asosiasi

Temukan asosiasi yang sesuai

```go
db.Model(&user).Association("Languages").Find(&languages)
```

### Tambahkan Asosiasi

Tambahkan asosiasi baru untuk `banyak ke banyak`, `memiliki banyak`, ganti asosiasi saat ini untuk`memiliki satu`, `milik`

```go
db.Model(&user).Association("Languages").Append([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Append(Language{Name: "DE"})
```

### Menggantikan Asosiasi

Ganti asosiasi saat ini dengan yang baru

```go
db.Model(&user).Association("Languages").Replace([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Replace(Language{Name: "DE"}, languageEN)
```

### Hapus Asosiasi

Hapus hubungan antara sumber & obyek argumen, hanya menghapus referensi, tidak akan menghapus objek dari DB.

```go
db.Model(&user).Association("Languages").Delete([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Delete(languageZH, languageEN)
```

### Asosiasi yang Jelas

Hapus referensi antara sumber & asosiasi saat ini, tidak akan menghapus asosiasi tersebut

```go
db.Model(&user).Association("Languages").Clear()
```

### Count Asosiasi

Kembali hitungan asosiasi saat ini

```go
db.Model(&user).Association("Languages").Count()
```