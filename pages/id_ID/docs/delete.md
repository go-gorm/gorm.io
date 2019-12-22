---
title: Hapus
layout: page
---

## Hapus Baris Data

**PERINGATAN** Saat menghapus baris data, anda harus memastikan kolom utama itu memiliki nilai, dan GORM akan menggunakan kolom kunci utama untuk menghapus catatan, jika kolom kunci utama kosong, GORM akan menghapus semua baris data untuk model tersebut

```go
// Menghapus baris data terkini
db.Delete(&email)
//// DELETE from emails where id=10;

// Tambal opsi extra SQL untuk penghapusan SQL
db.Set("gorm:delete_option", "OPTION (OPTIMIZE FOR UNKNOWN)").Delete(&email)
//// DELETE from emails where id=10 OPTION (OPTIMIZE FOR UNKNOWN);
```

## Hapus Masal

Hapus seluruh baris yang cocok dengan kondisi

```go
db.Where("email LIKE ?", "%jinzhu%").Delete(Email{})
//// DELETE from emails where email LIKE "%jinzhu%";

db.Delete(Email{}, "email LIKE ?", "%jinzhu%")
//// DELETE from emails where email LIKE "%jinzhu%";
```

## Hapus sementara

Jika sebuah model mempunyai kolom `DeletedAt` maka akan aktif fitur menghapus sementara! Dan ketika memanggil fungsi `Delete`, baris data tersebut tidak akan di hapus secara permanen dari database. Melainkan nilai dari `DeletedAt` akan terisi dengan waktu sekarang

```go
db.Delete(&user)
//// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE id = 111;

// Batch Delete
db.Where("age = ?", 20).Delete(&User{})
//// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE age = 20;

// Soft deleted records will be ignored when query them
db.Where("age = 20").Find(&user)
//// SELECT * FROM users WHERE age = 20 AND deleted_at IS NULL;

// Find soft deleted records with Unscoped
db.Unscoped().Where("age = 20").Find(&users)
//// SELECT * FROM users WHERE age = 20;
```

## Hapus baris data permanen

    // Delete record permanently with Unscoped
    db.Unscoped().Delete(&order)
    //// DELETE FROM orders WHERE id=10;