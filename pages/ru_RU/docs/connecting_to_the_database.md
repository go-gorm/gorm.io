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

**ПРИМЕЧАНИЕ:**

Для корректной обработки `time.Time`, вам нужно включить `parseTime` в качестве параметра. ([больше параметров](https://github.com/go-sql-driver/mysql#parameters))

Чтобы полностью поддерживать кодировку UTF-8, необходимо изменить `charset=utf8` на `charset=utf8mb4`. Смотрите [эту статью](https://mathiasbynens.be/notes/mysql-utf8mb4) для подробностей

MySQl Driver предоставляет [несколько расширенных настроек](https://github.com/go-gorm/mysql), которые можно использовать при инициализации, например:

```go
db, err := gorm.Open(mysql.New(mysql.Config{
  DSN: "gorm:gorm@tcp(127.0.0.1:3306)/gorm?charset=utf8&parseTime=True&loc=Local", // имя источника данных
  DefaultStringSize: 256, // размер по умолчанию для строковых полей
  DisableDatetimePrecision: true, // выключаем точность datetime, которая не поддерживается до MySQL 5.
  DontSupportRenameIndex: true, // drop & create когда переименовывается индекс переименование индекса не поддерживается до MySQL 5. , MariaDB
  DontSupportRenameColumn: true, // `change` when rename column, rename column not supported before MySQL 8, MariaDB
  SkipInitializeWithVersion: false, // auto configure based on used version
}), &gorm. нарисовать {})
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

Мы используем [pgx](https://github.com/jackc/pgx) в качестве драйвера базы данных sql postgres, он разрешает кэш подготовленных выражений по умолчанию, чтобы отключить его:

```go
// https://github.com/go-gorm/postgres
db, err := gorm.Open(postgres.New(postgres.Config{
  DSN: "user=gorm password=gorm dbname=gorm port=9920 sslmode=disable TimeZone=Asia/Shanghai",
  PreferSimpleProtocol: true, // отключает неявное использование statement
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

**ПРИМЕЧАНИЕ:** Вы также можете использовать `file::memory:?cache=shared` вместо пути к файлу. Это позволит SQLite использовать временную базу данных в системной памяти. (Смотрите [SQLite документацию](https://www.sqlite.org/inmemorydb.html) для подробностей)

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

Microsoft предлагает [руководство](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/) по использованию SQL Server с Go (и GORM).

## Пул подключений

GORM использует \[database/sql\]((https://pkg.go.dev/database/sql) для поддержки пула подключения

```go
sqlDB, err := db.DB()

// SetMaxIdleConns устанавливает максимальное количество соединений в пуле простоя.
sqlDB.SetMaxIdleConns(10)

// SetMaxOpenConns устанавливает максимальное количество открытых подключений к базе данных.
sqlDB.SetMaxOpenConns(100)

// SetConnMaxLifetime устанавливает максимальное время повторного использования.
sqlDB.SetConnMaxLifetime(time.Hour)
```

Смотрите [Общий интерфейс](generic_interface.html) для подробностей

## Неподдерживаемые базы данных

Некоторые базы данных могут быть совместимы с `mysql` или `postgres` диалектами, в этом случае можно просто использовать диалект для этих баз данных.

Для других, [вам предлагается сделать драйвер, pull request приветствуется!](write_driver.html)
