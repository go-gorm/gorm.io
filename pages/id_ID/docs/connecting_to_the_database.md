---
title: Menghubungkan ke database
layout: page
---

## Menghubungkan ke database

Agar bisa terhubung ke database, anda perlu mengimpor driver database terlebih dahulu. Sebagai contoh:

```go
import _ "github.com/go-sql-driver/mysql"
```

GORM telah memasukkan beberapa driver, untuk mempermudah mengingat jalur impor mereka, sehingga anda bisa mengimpor driver mysql dengan:

```go
import _ "github.com/jinzhu/gorm/dialects/mysql"
// import _ "github.com/jinzhu/gorm/dialects/postgres"
// import _ "github.com/jinzhu/gorm/dialects/sqlite"
// import _ "github.com/jinzhu/gorm/dialects/mssql"
```

## Basisdata yang didukung

### MySQL

**CATATAN:**

Untuk menggunakan `time.Time` secara benar, anda harus menyisipkan `parseTime` sebagai sebuah parameter. ([Lihat parameter yang di dukung](https://github.com/go-sql-driver/mysql#parameters))

Demi mendukung UTF-8 encoding secara penuh, anda harus mengubah `charset=utf8` ke `charset=utf8mb4`. Lihat [artikel ini](https://mathiasbynens.be/notes/mysql-utf8mb4) untuk penjelasan lebih lanjut.

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

Jika anda mau menentukan host, gunakanlah `()`. Contoh:

    user:password@(localhost)/dbname?charset=utf8&parseTime=True&loc=Local
    

### PostgreSQL

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

### Sqlite3

**NOTE:** You can also use `:memory:` instead of a path to a file. Ini akan membuat sqlite menggunakan database sementara dalam memori sistem. Ini sangat berguna ketika menulis program test untuk aplikasi GORM anda, test anda menggunakan aktual database, tetapi punya keunggulan performa dikarena database ada di dalam memori.

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

### Server SQL

[Get started with SQL Server](https://www.microsoft.com/en-us/sql-server/developer-get-started/go), dapat perjalan di [Mac](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/go/mac/), [Linux](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/go/ubuntu/) menggunakan Docker

```go
import (
  "github.com/jinzhu/gorm"
  _ "github.com/jinzhu/gorm/dialects/mssql"
)

func main() {
  db, err := gorm.Open("mssql", "sqlserver://username:password@localhost:1433?database=dbname")
  defer db.Close()
}
```

## Basisdata yang tidak didukung

GORM secara resmi mendukung di atas empat database, anda bisa menulis dialek untuk database yang tidak didukung, lihat [Dialek GORM](/docs/dialects.html)