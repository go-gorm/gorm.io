---
title: Подключение к базе данных
layout: страница
---

GORM официально поддерживает базы данных MySQL, PostgreSQL, SQlite, SQL Server

## MySQL

```go
import (
  "gorm.io/driver/mysql"
  "gorm.io/gorm"
)

func main() {
  // смотрите https://github.com/go-sql-driver/mysql#dsn-data-source-name для подробностей
  dsn := "user:pass@tcp(127.0.0.1:3306)/dbname?charset=utf8mb4&parseTime=True&loc=Local"
  db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
}
```

{% note warn %}
**ПРИМЕЧАНИЕ:** Для корректной обработки `time.Time`, вам нужно включить `parseTime` как параметр. ([больше параметров](https://github.com/go-sql-driver/mysql#parameters)) Для полной поддержки кодировки UTF-8, вам необходимо изменить `charset=utf8` на `charset=utf8mb4`. Смотрите [эту статью](https://mathiasbynens.be/notes/mysql-utf8mb4) для подробностей
{% endnote %}

Драйвер MySQL предоставляет [несколько расширенных настроек](https://github.com/go-gorm/mysql), которые можно использовать при инициализации, например:

```go
db, err := gorm.Open(mysql.New(mysql.Config{
  DSN: "gorm:gorm@tcp(127.0.0.1:3306)/gorm?charset=utf8&parseTime=True&loc=Local", // имя источника данных
  DefaultStringSize: 256, // размер значения по умолчанию для строковых полей
  DisableDatetimePrecision: true, // отключить точность полей типа datetime, которая не поддерживается до версии MySQL 5.6
  DontSupportRenameIndex: true, // drop & create при переименовании индекса, переименование индекса не поддерживается с версии MySQL 5.7, MariaDB
  DontSupportRenameColumn: true, // `change` when rename column, rename column not supported before MySQL 8, MariaDB
  SkipInitializeWithVersion: false, // авто найтройка в зависимости от текущей весрии MySQL
}), &gorm.Config{})
```

### Настройка драйвера

GORM позволяет настроить драйвер MySQL, используя опции `DriverName`, например:

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

### Существующие подключения к базе данных

GORM позволяет инициализировать `*gorm.DB` с существующим соединением с базой данных

```go
import (
  "database/sql"
  "gorm.io/driver/mysql"
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

Мы используем [pgx](https://github.com/jackc/pgx) в качестве драйвера sql базы данных postgres, он включает кэш подготовленных выражений по умолчанию, чтобы отключить его:

```go
// https://github.com/go-gorm/postgres
db, err := gorm.Open(postgres.New(postgres.Config{
  DSN: "user=gorm password=gorm dbname=gorm port=9920 sslmode=disable TimeZone=Asia/Shanghai",
  PreferSimpleProtocol: true, // disables implicit prepared statement usage
}), &gorm.Config{})
```

### Настройка драйвера

GORM позволяет настроить драйвер PostgreSQL, используя опции `DriverName`, например:

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

### Существующие подключения к базе данных

GORM позволяет инициализировать `*gorm.DB` с существующим соединением с базой данных

```go
import (
  "database/sql"
  "gorm.io/driver/postgres"
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
  "gorm.io/driver/sqlite" // Sqlite driver based on GGO
  // "github.com/glebarez/sqlite" // Pure go SQLite driver, checkout https://github.com/glebarez/sqlite for details
  "gorm.io/gorm"
)

// github.com/mattn/go-sqlite3
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{})
```

{% note warn %}
**ПРИМЕЧАНИЕ:** Вы также можете использовать `file::memory:?cache=shared` вместо пути к файлу. Это позволит SQLite использовать временную базу данных в системной памяти. (Смотрите [SQLite документацию](https://www.sqlite.org/inmemorydb.html) для подробностей)
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

  // Insert партиями
  var users = []User{user1, user2, user3}
  db.Create(&users)
  // ...
}
```

## Пул соединений

GORM использует [database/sql](https://pkg.go.dev/database/sql) для поддержания пула соединений

```go
sqlDB, err := db.DB()

// SetMaxIdleConns устанавливает максимальное количество соединений в пуле незанятых соединений.
sqlDB.SetMaxIdleConns(10)

// SetMaxOpenConns устанавливает максимальное количество открытых подключений к базе данных.
sqlDB.SetMaxOpenConns(100)

// SetConnMaxLifetime устанавливает максимальное количество времени, в течение которого соединение может быть повторно использовано.
sqlDB.SetConnMaxLifetime(time.Hour)
```

Смотрите подробнее в [Generic Interface](generic_interface.html)

## Неподдерживаемые базы данных

Некоторые базы данных могут быть совместимы с диалектами `mysql` или `postgres`, в этом случае можно просто использовать диалект для этих баз данных.

Для других баз данных, [вам предлагается сделать драйвер самостоятельно, pull request приветствуется!](write_driver.html)
