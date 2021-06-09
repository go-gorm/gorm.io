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

{% note warn %}
**NOTE:** To handle `time.Time` correctly, you need to include `parseTime` as a parameter. ([more parameters](https://github.com/go-sql-driver/mysql#parameters)) To fully support UTF-8 encoding, you need to change `charset=utf8` to `charset=utf8mb4`. See [this article](https://mathiasbynens.be/notes/mysql-utf8mb4) for a detailed explanation
{% endnote %}

MySQLドライバは、 [初期化中に使用できる高度な設定](https://github. com/go-gorm/mysql)を いくつか提供しています。

```go
db, err := gorm.Open(mysql.New(mysql.Config{
  DSN: "gorm:gorm@tcp(127.0.0.1:3306)/gorm?charset=utf8&parseTime=True&loc=Local", // data source name
  DefaultStringSize: 256, // default size for string fields
  DisableDatetimePrecision: true, // disable datetime precision, which not supported before MySQL 5.6
  DontSupportRenameIndex: true, // drop & create when rename index, rename index not supported before MySQL 5.7, MariaDB
  DontSupportRenameColumn: true, // `change` when rename column, rename column not supported before MySQL 8, MariaDB
  SkipInitializeWithVersion: false, // auto configure based on currently MySQL version
}), &gorm.Config{})
```

### Customize Driver

GORMでは、 `DriverName` オプションを使用してMySQLドライバをカスタマイズできます。

```go
import (
  _ "example.com/my_mysql_driver"
  "gorm.io/gorm"
)

db, err := gorm.Open(mysql.New(mysql.Config{
  DriverName: "my_mysql_driver",
  DSN: "gorm:gorm@tcp(localhost:9910)/gorm?charset=utf8&parseTime=True&loc=Local", // data source name, refer https://github.com/go-sql-driver/mysql#dsn-data-source-name
}), &gorm.Config{})
```

### Existing database connection

GORMでは、既存のデータベース接続で `*gorm.DB` を初期化することができます。

```go
import (
  "database/sql"
  "gorm.io/gorm"
)

sqlDB, err := sql.Open("mysql", "mydb_dsn")
gormDB, err := gorm.Open(mysql.New(mysql.Config{
  Conn: sqlDB,
}), &gorm.Config{})
```

## PostgreSQL

```go
import (
  "gorm.io/driver/postgres"
  "gorm.io/gorm"
)

dsn := "host=localhost user=gorm password=gorm dbname=gorm port=9920 sslmode=disable TimeZone=Asia/Shanghai"
db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
```

Postgresのdatabase/sqlドライバとして [pgx](https://github.com/jackc/pgx) を使用しています。これはデフォルトでprepared statement cacheを有効にしています。無効にするには:

```go
// https://github.com/go-gorm/postgres
db, err := gorm.Open(postgres.New(postgres.Config{
  DSN: "user=gorm password=gorm dbname=gorm port=9920 sslmode=disable TimeZone=Asia/Shanghai",
  PreferSimpleProtocol: true, // disables implicit prepared statement usage
}), &gorm.Config{})
```

### ドライバーのカスタマイズ

GORMでは、 `DriverName` オプションを使用してPostgreSQLドライバをカスタマイズできます。例:

```go
import (
  _ "github.com/GoogleCloudPlatform/cloudsql-proxy/proxy/dialers/postgres"
  "gorm.io/gorm"
)

db, err := gorm.Open(postgres.New(postgres.Config{
  DriverName: "cloudsqlpostgres",
  DSN: "host=project:region:instance user=postgres dbname=postgres password=password sslmode=disable",
})
```

### 既存のデータベース接続

GORMでは、既存のデータベース接続で `*gorm.DB` を初期化することができます

```go
import (
  "database/sql"
  "gorm.io/gorm"
)

sqlDB, err := sql.Open("postgres", "mydb_dsn")
gormDB, err := gorm.Open(postgres.New(postgres.Config{
  Conn: sqlDB,
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

{% note warn %}
**NOTE:** You can also use `file::memory:?cache=shared` instead of a path to a file. This will tell SQLite to use a temporary database in system memory. (See [SQLite docs](https://www.sqlite.org/inmemorydb.html) for this)
{% endnote %}

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

## Clickhouse

https://github.com/go-gorm/clickhouse

```go
import (
  "gorm.io/driver/clickhouse"
  "gorm.io/gorm"
)

func main() {
  dsn := "tcp://localhost:9000?database=gorm&username=gorm&password=gorm&read_timeout=10&write_timeout=20"
  db, err := gorm.Open(clickhouse.Open(dsn), &gorm.Config{})

  // Auto Migrate
  db.AutoMigrate(&User{})
  // Set table options
  db.Set("gorm:table_options", "ENGINE=Distributed(cluster, default, hits)").AutoMigrate(&User{})

  // Insert
  db.Create(&user)

  // Select
  db.Find(&user, "id = ?", 10)

  // Batch Insert
  var users = []User{user1, user2, user3}
  db.Create(&users)
  // ...
}
```

## Connection Pool

GORMによる[database/sql](https://pkg. go. dev/database/sql) を使用したコネクションプールの維持

```go
sqlDB, err := db.DB()

// SetMaxIdleConns sets the maximum number of connections in the idle connection pool.
sqlDB.SetMaxIdleConns(10)

// SetMaxOpenConns sets the maximum number of open connections to the database.
sqlDB.SetMaxOpenConns(100)

// SetConnMaxLifetime sets the maximum amount of time a connection may be reused.
sqlDB.SetConnMaxLifetime(time.Hour)
```

詳細については、 [Generic Interface](generic_interface. html) を参照してください。

## Unsupported Databases

いくつかのデータベースは `mysql` または `postgres` の方言と互換性があります。 その場合はデータベースの方言を使うことができます

For others, [you are encouraged to make a driver, pull request welcome!](write_driver.html)
