---
title: Asosiasi
layout: halaman
---
## Auto Create/Update

GORM akan menyimpan otomatis asosiasi dan referensi saat membuat / memperbarui rekama. Jika asosiasi memiliki kunci utama, GORM akan memanggil ` Perbarui ` untuk menyimpannya, jika tidak maka akan dibuat.

```go
user := User{
    Name:            "jinzhu",
    BillingAddress:  Address{Address1: "Billing Address - Address 1"},
    ShippingAddress: Address{Address1: "Shipping Address - Address 1"},
    Emails:          []Email{
        {Email: "jinzhu@example.com"},
        {Email: "jinzhu-2@example@example.com"},
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

## Skip AutoUpdate

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

## Skip AutoCreate

Even though you disabled `AutoUpdating`, associations w/o primary key still have to be created and its reference will be saved.

Untuk menonaktifkan ini, anda dapat mengatur pengaturan DB `gorm:association_autocreate` ke `false`

```go
// Don't create associations w/o primary key, WON'T save its reference
db.Set("gorm:association_autocreate", false).Create(&user)
db.Set("gorm:association_autocreate", false).Save(&user)
```

atau gunakan label GORM, `gorm:"association_autocreate:false"
`

    type User struct {
      gorm.Model
      Name       string
      // Don't create associations w/o primary key, WON'T save its reference
      Company1   Company `gorm:"association_autocreate:false"`
    }
    

## Skip AutoCreate/Update

Untuk menonaktifkan `AutoCreate` dan `AutoUpdate`, anda dapat menggunakan dua pengaturan itu secara bersamaan

```go
db.Set("gorm:association_autoupdate", false).Set("gorm:association_autocreate", false).Create(&user)

type User struct {
  gorm.Model
  Name    string
  Company Company `gorm:"association_autoupdate:false;association_autocreate:false"`
}
```

Atau gunakan `gorm:save_associations`

    db.Set("gorm:save_associations", false).Create(&user)
    db.Set("gorm:save_associations", false).Save(&user)
    
    type User struct {
      gorm.Model
      Name    string
      Company Company `gorm:"association_autoupdate:false"`
    }
    

## Skip Save Reference

If you don't even want to save association's reference when updating/saving data, you could use below tricks

```go
db.Set("gorm:association_save_reference", false).Save(&user)
db.Set("gorm:association_save_reference", false).Create(&user)
```

or use tag

```go
type User struct {
  gorm.Model
  Name       string
  CompanyID  uint
  Company    Company `gorm:"association_save_reference:false"`
}
```

## Association Mode

Asosiasi motede berisi beberapa metode penolong untuk menangani hal-hal yang berhubungan dengan hubungan dengan mudah.

```go
// Start Association Mode
var user User
db.Model(&user).Association("Languages")
// `user` is the source, is must contains primary key
// `Languages` is source's field name for a relationship
// AssociationMode can only works if above two conditions both matched, check it ok or not:
// db.Model(&user).Association("Languages").Error
```

### Find Associations

Find matched associations

```go
db.Model(&user).Association("Languages").Find(&languages)
```

### Tambahkan Asosiasi

Append new associations for `many to many`, `has many`, replace current associations for `has one`, `belongs to`

```go
db.Model(&user).Association("Languages").Append([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Append(Language{Name: "DE"})
```

### Replace Associations

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

### Clear Associations

Remove reference between source & current associations, won't delete those associations

```go
db.Model(&user).Association("Languages").Clear()
```

### Count Associations

Return the count of current associations

```go
db.Model(&user).Association("Languages").Count()
```