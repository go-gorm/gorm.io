---
title: Transactions
layout: page
---
GORM perform single `create`, `update`, `delete` operations in transactions by default to ensure database data integrity.

If you want to tread multiple `create`, `update`, `delete` as one atomic operation, `Transaction` is made for that.

## Transaksi

Untuk melakukan serangkaian operasi dalam suatu transaksi, arus umum adalah sebagai berikut.

```go
// Mulai transaksi
tx := db.Mulai()

// lakukan beberapa operasi database dalam transaksi (gunakan 'tx' dari poin ini, tidak 'db')
tx.buat(...)

// ...

// kembalikan transaksi jika terjadi kesalahan
tx.kembalikan()

// Atau lakukan transaksi
tx.Melakukan()
```

## Sebuah contoh khusus

```go
func CreateAnimals(db *gorm.DB) err {
  // Note the use of tx as the database handle once you are within a transaction
  tx := db.Begin()
  defer func() {
    if r := recover(); r != nil {
      tx.Rollback()
    }
  }()

  if tx.Error != nil {
    return err
  }

  if err := tx.Create(&Animal{Name: "Giraffe"}).Error; err != nil {
     tx.Rollback()
     return err
  }

  if err := tx.Create(&Animal{Name: "Lion"}).Error; err != nil {
     tx.Rollback()
     return err
  }

  return tx.Commit().Error
}
```