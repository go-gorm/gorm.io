---
title: Menghubungkan ke basis data
layout: page
---

# Menghubungkan ke basisdata

Agar bisa terhubung ke database, anda perlu mengimpor driver database terlebih dahulu. Sebagai contoh:

```go
import _ "github.com/go-sql-driver/mysql"
```

GORM sudah termasuk beberapa driver, untuk mempermudah mengingat jalur impor mereka, sehingga anda bisa mengimpor driver mysql dengan:

```go
import _ "github.com/jinzhu/gorm/dialects/mysql"
// import _ "github.com/jinzhu/gorm/dialects/postgres"
// import _ "github.com/jinzhu/gorm/dialects/sqlite"
// import _ "github.com/jinzhu/gorm/dialects/mssql"
```

## MySQL

**CATATAN:**Untuk menggunakan `time.Time` secara benar, anda harus menyisipkan `parseTime` sebagai sebuah parameter. ([Lihat parameter yang di dukung](https://github.com/go-sql-driver/mysql#parameters))

```go
import (
    "github.com/jinzhu/gorm"
    _ "github.com/jinzhu/gorm/dialects/mysql"
)

func main() {
  db, err := gorm.Open("mysql", "user:password@/dbname?charset=utf8&parseTime=True&loc=Local")
  defer db.Close()
}
```

## PostgreSQL

```go
import (
    "github.com/jinzhu/gorm"
    _ "github.com/jinzhu/gorm/dialects/postgres"
)

func main() {
  db, err := gorm.Open("postgres", "host=myhost port=myport user=gorm dbname=gorm password=mypassword")
  defer db.Close()
}
```

## Sqlite3

**CATATAN:** Anda dapat menggunakan `:memory:` untuk koneksinya, yang hal itu sqlite akan menggunakan sistem memory yang sementara. Ini sangat berguna untuk membuat program test aplikasi GORM punya anda.

```go
import (
    "github.com/jinzhu/gorm"
    _ "github.com/jinzhu/gorm/dialects/sqlite"
)

func main() {
  db, err := gorm.Open("sqlite3", "/tmp/gorm.db")
  defer db.Close()
}
```

## Server SQL

[Get started with SQL Server](https://www.microsoft.com/en-us/sql-server/developer-get-started/go), dapat perjalan di [Mac](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/go/mac/), [Linux](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/go/ubuntu/) menggunakan Docker

```go
import (
    "github.com/jinzhu/gorm"
    _ "github.com/jinzhu/gorm/dialects/mssql"
)

func main() {
  db, err = gorm.Open("mssql", "sqlserver://username:password@localhost:1433?database=dbname")
  defer db.Close()
}
```

## Tulis Dialek untuk basis data yang tidak didukung

GORM secara resmi mendukung database di atas, tapi anda bisa menulis dialek untuk database yang tidak didukung.

Untuk menulis dialek anda sendiri, lihat: <https://github.com/jinzhu/gorm/blob/master/dialect.go>