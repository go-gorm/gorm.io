---
title: Antarmuka basisdata generik sql.DB
layout: halaman
---
GORM menyediakan metode `DB` yang mengembalikan antarmuka basisdata generik [*sql.DB](http://golang.org/pkg/database/sql/#DB) dari koneksi `*gorm.DB` saat ini

```go
// Dapatkan objek basisdata generik sql.DB untuk menggunakan fungsinya
db.DB()

// Ping
db.DB().Ping()
```

**CATATAN** Jika koneksi basisdata yang mendasarinya bukan sebuah `*sql.DB`, seperti dalam sebuah transaksi, ia akan kembali nihil

## Kelompok Koneksi

```go
// SetMaxIdleConns tetapkan jumlah maksimum dari koneksi dalam kelompok koneksi diam.
db.DB().SetMaxIdleConns(10)

// SetMaxOpenConns atur jumlah maksimum koneksi terbuka ke basis data.
db.DB().SetMaxOpenConns(100)

// SetConnMaxLifetime tetapkan nilai maksimum dari waktu sebuah koneksi mungkin digunakan kembali.
db.DB().SetConnMaxLifetime(time.Hour)
```