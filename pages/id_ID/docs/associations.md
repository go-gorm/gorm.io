---
title: Asosiasi
layout: page
---

## Buat/Pembaruan Otomatis

GORM akan menyimpan asosiasi dan referensinya secara otomatis menggunakan [Upsert](create.html#upsert) saat membuat/memperbarui catatan.

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
// BEGIN TRANSACTION;
// INSERT INTO "addresses" (address1) VALUES ("Billing Address - Address 1"), ("Shipping Address - Address 1") ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "users" (name,billing_address_id,shipping_address_id) VALUES ("jinzhu", 1, 2);
// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu@example.com"), (111, "jinzhu-2@example.com") ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "languages" ("name") VALUES ('ZH'), ('EN') ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "user_languages" ("user_id","language_id") VALUES (111, 1), (111, 2) ON DUPLICATE KEY DO NOTHING;
// COMMIT;

db.Save(&user)
```

Jika Anda ingin memperbarui data asosiasi, Anda harus menggunakan mode `FullSaveAssociations`:

```go
db.Session(&gorm.Session{FullSaveAssociations: true}).Updates(&user)
// ...
// INSERT INTO "addresses" (address1) VALUES ("Billing Address - Address 1"), ("Shipping Address - Address 1") ON DUPLICATE KEY SET address1=VALUES(address1);
// INSERT INTO "users" (name,billing_address_id,shipping_address_id) VALUES ("jinzhu", 1, 2);
// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu@example.com"), (111, "jinzhu-2@example.com") ON DUPLICATE KEY SET email=VALUES(email);
// ...
```

## Lewati Buat/Pembaruan Otomatis

Untuk melewati simpan otomatis saat membuat/memperbarui, Anda dapat menggunakan `Select` atau `Omit`, misalnya:

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

db.Select("Name").Create(&user)
// INSERT INTO "users" (name) VALUES ("jinzhu", 1, 2);

db.Omit("BillingAddress").Create(&user)
// Lewati pembuatan BillingAddress saat membuat pengguna baru

db.Omit(clause.Associations).Create(&user)
// Lewati semua asosiasi saat membuat pengguna
```

{% note warn %}
**CATATAN:** Untuk asosiasi bangak-ke-banyak GORM akan melakukan upsert pada asosiasi sebelum membuat referensi tabel join, jika anda ingin melewatkan upserting dari asosiasi, anda dapat melewatinya seperti:

```go
db.Omit("Languages.*").Create(&user)
```

Kode berikut akan melewatkan pembuatan asosiasi dan referensinya

```go
db.Omit("Languages").Create(&user)
```
{% endnote %}

## Pilih/Abaikan bidang Asosiasi

```go
user := User{
  Name:            "jinzhu",
  BillingAddress:  Address{Address1: "Billing Address - Address 1", Address2: "addr2"},
  ShippingAddress: Address{Address1: "Shipping Address - Address 1", Address2: "addr2"},
}

// Buat pengguna dan BillingAddress-nya, ShippingAddress
// Saat membuat BillingAddress hanya gunakan field address1, address2 dan hilangkan yang lain
db.Select("BillingAddress.Address1", "BillingAddress.Address2").Create(&user)

db.Omit("BillingAddress.Address2", "BillingAddress.CreatedAt").Create(&user)
```

## Mode Asosiasi

Mode Asosiasi berisi beberapa metode pembantu yang umum digunakan untuk menangani hubungan

```go
// Mulai mode asosiasi
var user User
db.Model(&user).Association("Languages")
// `user` adalah model sumber, harus berisi kunci utama
// `Languages` adalah nama bidang hubungan
// Jika dua persyaratan di atas cocok, Mode Asosiasi harus dimulai dengan sukses, atau itu akan mengembalikan kesalahan
db.Model(&user).Association("Languages").Error
```

### Cari Asosiasi

Cari asosiasi yang sesuai

```go
db.Model(&user).Association("Languages").Find(&languages)
```

Cari asosiasi dengan kondisi

```go
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Find(&languages)

db.Model(&user).Where("code IN ?", codes).Order("code desc").Association("Languages").Find(&languages)
```

### Menambahkan Asosiasi

Tambahkan asosiasi baru untuk `many to many`, `has many`, ganti asosiasi saat ini untuk `has one`, `belongs to`

```go
db.Model(&user).Association("Languages").Append([]Language{languageZH, languageEN})

db.Model(&user).Association("Languages").Append(&Language{Name: "DE"})

db.Model(&user).Association("CreditCard").Append(&CreditCard{Number: "411111111111"})
```

### Ubah Asosiasi

Ganti asosiasi saat ini dengan yang baru

```go
db.Model(&user).Association("Languages").Replace([]Language{languageZH, languageEN})

db.Model(&user).Association("Languages").Replace(Language{Name: "DE"}, languageEN)
```

### Hapus Asosiasi

Hapus hubungan antara sumber & argumen jika ada, hanya hapus referensi, tidak akan menghapus objek tersebut dari DB.

```go
db.Model(&user).Association("Languages").Delete([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Delete(languageZH, languageEN)
```

### Bersihkan Asosiasi

Hapus semua referensi antara sumber & asosiasi, tidak akan menghapus asosiasi tersebut

```go
db.Model(&user).Association("Languages").Clear()
```

### Hitung Asosiasi

Kembalikan jumlah asosiasi saat ini

```go
db.Model(&user).Association("Languages").Count()

// Count with conditions
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Count()
```

### Data Batch

Mode Asosiasi mendukung data batch, mis:

```go
// Cari semua peran untuk semua pengguna
db.Model(&users).Association("Role").Find(&roles)

// Hapus Pengguna A dari semua tim pengguna
db.Model(&users).Association("Team").Delete(&userA)

// Dapatkan hitungan berbeda dari semua tim pengguna
db.Model(&users).Association("Team").Count()

// Untuk `Append`, `Replace` dengan data batch, panjang argumen harus sama dengan panjang data atau akan mengembalikan kesalahan
var pengguna = []User{user1, user2, user3}
// misalnya: kami memiliki 3 pengguna, Tambahkan penggunaA ke tim pengguna1, tambahkan penggunaB ke tim pengguna2, tambahkan penggunaA, penggunaB, dan penggunaC ke tim pengguna3
db.Model(&users).Association("Team").Append(&userA, &userB, &[]User{userA, userB, userC})
// Setel ulang tim pengguna1 ke penggunaA，setel ulang tim pengguna2 ke penggunaB, setel ulang tim pengguna3 ke penggunaA, penggunaB, dan penggunaC
db.Model(&users).Association("Team").Replace(&userA, &userB, &[]User{userA, userB, userC})
```

## <span id="delete_association_record">Delete Association Record</span>

By default, `Replace`/`Delete`/`Clear` in `gorm.Association` only delete the reference, that is, set old associations's foreign key to null.

You can delete those objects with `Unscoped` (it has nothing to do with `ManyToMany`).

How to delete is decided by `gorm.DB`.

```go
// Soft delete
// UPDATE `languages` SET `deleted_at`= ...
db.Model(&user).Association("Languages").Unscoped().Clear()

// Delete permanently
// DELETE FROM `languages` WHERE ...
db.Unscoped().Model(&item).Association("Languages").Unscoped().Clear()
```

## <span id="delete_with_select">Delete with Select</span>

You are allowed to delete selected has one/has many/many2many relations with `Select` when deleting records, for example:

```go
// delete user's account when deleting user
db.Select("Account").Delete(&user)

// delete user's Orders, CreditCards relations when deleting user
db.Select("Orders", "CreditCards").Delete(&user)

// delete user's has one/many/many2many relations when deleting user
db.Select(clause.Associations).Delete(&user)

// delete each user's account when deleting users
db.Select("Account").Delete(&users)
```

{% note warn %}
**NOTE:** Associations will only be deleted if the deleting records's primary key is not zero, GORM will use those primary keys as conditions to delete selected associations

```go
// DOESN'T WORK
db.Select("Account").Where("name = ?", "jinzhu").Delete(&User{})
// will delete all user with name `jinzhu`, but those user's account won't be deleted

db.Select("Account").Where("name = ?", "jinzhu").Delete(&User{ID: 1})
// will delete the user with name = `jinzhu` and id = `1`, and user `1`'s account will be deleted

db.Select("Account").Delete(&User{ID: 1})
// will delete the user with id = `1`, and user `1`'s account will be deleted
```
{% endnote %}

## <span id="tags">Association Tags</span>

| Tag              | Deskripsi                                                                                      |
| ---------------- | ---------------------------------------------------------------------------------------------- |
| foreignKey       | Menentukan nama kolom dari model saat ini yang digunakan sebagai kunci asing ke tabel gabungan |
| references       | Menentukan nama kolom tabel referensi yang dipetakan ke kunci asing tabel gabungan             |
| polymorphic      | Menentukan tipe polimorfik seperti nama model                                                  |
| polymorphicValue | Menentukan nilai polimorfik, nama tabel default                                                |
| many2many        | Menentukan nama tabel yang digabung                                                            |
| joinForeignKey   | Menentukan nama kolom kunci asing dari tabel gabungan yang memetakan ke tabel saat ini         |
| joinReferences   | Menentukan nama kolom kunci asing dari tabel gabungan yang memetakan ke tabel referensi        |
| constraint       | Batasan relasi, mis: `OnUpdate`,`OnDelete`                                                     |
