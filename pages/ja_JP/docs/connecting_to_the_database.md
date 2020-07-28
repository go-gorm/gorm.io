---
title: Connecting to a Database
layout: page
---

GORMは公式にMySQL、PostgreSQL、SQLite、SQL Server をサポートしています

## MySQL

```go
import (
  "gorm.io/driver/mysql"
  "gorm.io/gorm"
)

func main() {
  // 詳細は https://github.com/go-sql-driver/mysql#dsn-data-source-name を参照
  dsn := "user:pass@tcp(127.0.0.1:3306)/dbname?charset=utf8mb4&parseTime=True&loc=Local"
  db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
}
```

**注:**

`time.Time` を正しく処理するには、パラメータとして `parseTime` を含める必要があります。 ([more parameters](https://github.com/go-sql-driver/mysql#parameters))

UTF-8 エンコーディングを完全にサポートするには、 `charset=utf8` を `charset=utf8mb4` に変更する必要があります。 詳細な説明は [この記事](https://mathiasbynens.be/notes/mysql-utf8mb4) を参照してください。

MySQLドライバは、初期化中に利用できる [高度な設定](https://github.com/go-gorm/mysql) をいくつか用意しています。例えば、：

```go
db, err := gorm.Open(mysql.New(mysql.Config{
  DSN: "gorm:gorm@tcp(127.0.0.1:3306)/gorm?charset=utf8&parseTime=True&loc=Local", // data source name
  DefaultStringSize: 256, // default size for string fields
  DisableDatetimePrecision: true, // disable datetime precision, which not supported before MySQL 5.6
  DontSupportRenameIndex: true, // drop & create when rename index, rename index not supported before MySQL 5.7, MariaDB
  DontSupportRenameColumn: true, // `change` when rename column, rename column not supported before MySQL 8, MariaDB
  SkipInitializeWithVersion: false, // auto configure based on used version
}), &gorm.Config{})
```

## PostgreSQL

```go
import (
  "gorm.io/driver/postgres"
  "gorm.io/gorm"
)

dsn := "user=gorm password=gorm dbname=gorm port=9920 sslmode=disable TimeZone=Asia/Shanghai"
db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
```

Postgresのdatabase/sqlドライバとして [pgx](https://github.com/jackc/pgx) を使用しています。これはデフォルトでプリペアードステイトメントキャッシュを有効にしています。無効にするには:

```go
// https://github.com/go-gorm/postgres
db, err := gorm.Open(postgres.New(postgres.Config{
  DSN: "user=gorm password=gorm dbname=gorm port=9920 sslmode=disable TimeZone=Asia/Shanghai",
  PreferSimpleProtocol: true, // disables implicit prepared statement usage
}), &gorm.Config{})
```

## SQLite

```go
import (
  "gorm.io/driver/sqlite"
  "gorm.io/gorm"
)

// github.com/mattn/go-sqlite3
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{})
```

**NOTE:** You can also use `file::memory:?cache=shared` instead of a path to a file. This will tell SQLite to use a temporary database in system memory. (See [SQLite docs](https://www.sqlite.org/inmemorydb.html) for this)

## SQL Server

```go
import (
  "gorm.io/driver/sqlserver"
  "gorm.io/gorm"
)

// github.com/denisenkom/go-mssqldb
dsn := "sqlserver://gorm:LoremIpsum86@localhost:9930?database=gorm"
db, err := gorm.Open(sqlserver.Open(dsn), &gorm.Config{})
```

Microsoft offers [a guide](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/) for using SQL Server with Go (and GORM).

## Connection Pool

GORM using \[database/sql\]((https://pkg.go.dev/database/sql) to maintain connection pool

```go
sqlDB, err := db.DB()

// SetMaxIdleConns sets the maximum number of connections in the idle connection pool.
sqlDB.SetMaxIdleConns(10)

// SetMaxOpenConns sets the maximum number of open connections to the database.
sqlDB.SetMaxOpenConns(100)

// SetConnMaxLifetime sets the maximum amount of time a connection may be reused.
sqlDB.SetConnMaxLifetime(time.Hour)
```

Refer [Generic Interface](generic_interface.html) for details

## サポートされていないデータベース

いくつかのデータベースは `mysql` または `postgres` の方言と互換性があります。 その場合はデータベースの方言を使うことができます

その他のデータベースのために、 [ドライバーを作ることをお勧めします。プルリクエストを歓迎します！](write_driver.html)
