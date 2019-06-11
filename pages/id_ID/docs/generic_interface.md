---
title: Antarmuka basisdata generik sql.DB
layout: page
---

GORM provides the method `DB` which returns a generic database interface [*sql.DB](http://golang.org/pkg/database/sql/#DB) from the current `*gorm.DB` connection

```go
// Dapatkan objek basisdata generik sql.DB untuk menggunakan fungsinya
db.DB()

// Ping
db.DB().Ping()
```

**NOTE** If the underlying database connection is not a `*sql.DB`, like in a transaction, it will returns `nil`

## Kelompok Koneksi

```go
// SetMaxIdleConns tetapkan jumlah maksimum dari koneksi dalam kelompok koneksi diam.
db.DB().SetMaxIdleConns(10)

// SetMaxOpenConns atur jumlah maksimum koneksi terbuka ke basis data.
db.DB().SetMaxOpenConns(100)

// SetConnMaxLifetime tetapkan nilai maksimum dari waktu sebuah koneksi mungkin digunakan kembali.
db.DB().SetConnMaxLifetime(time.Hour)
```
