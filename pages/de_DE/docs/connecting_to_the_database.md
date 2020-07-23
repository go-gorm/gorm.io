---
title: Connecting to a Database
layout: page
---

GORM unterstüzt offiziell die MySQL, PostgreSQL, SQlite, SQL Server Datenbaken

## MySQL

```go
import (
  "gorm.io/driver/mysql"
  "gorm.io/gorm"
)

func main() {
  // auf https://github.com/go-sql-driver/mysql#dsn-data-source-name finden sich mehr Informationen
  dsn := "user:pass@tcp(127.0.0.1:3306)/dbname?charset=utf8mb4&parseTime=True&loc=Local"
  db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
}
```

**Hinweis:**

Um `time.Time` richtig zu handhaben. Muss man `parseTime` als Parameter einbinden. ([weitere Parameter](https://github.com/go-sql-driver/mysql#parameters))

Um die UTF-8-Kodierung vollständig zu unterstützen, müssen Sie `charset=utf8` auf `charset=utf8mb4` ändern. Siehe [diesen Artikel](https://mathiasbynens.be/notes/mysql-utf8mb4) für eine detaillierte Erklärung

Der MySQl-Treiber bietet [einige erweiterte Konfigurationen](https://github.com/go-gorm/mysql) die können während der Initialisierung verwendet werden können, zum Beispiel:

```go
db, err := gorm.Open(mysql.New(mysql.Config{
  DSN: "gorm:gorm@tcp(127.0.0. :3306)/gorm? harset=utf8&parseTime=True&loc=Local", // Datenquellname
  DefaultStringSize: 256, // Standardgröße für String-Felder
  DeableDatetimePrecision: true // Datumszeitpräzision deaktivieren, die vor MySQL 5 nicht unterstützt wird.
  DontSupportRenameIndex: true // Löschen & Umbenennen des Indexes, um den Index umzubenennen, der vor MySQL 5 nicht unterstützt wird. , MariaDB
  DontSupportRenameColumn: true // `change` wenn Spalte umbenannt wird, das umbenennen von Spalten wird nicht unterstützt vor MySQL 8, MariaDB
  SkipInitializeWithVersion: false, // autokonfiguration auf Basis des Verwendeten System
}), &gorm. onfig{})
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

Wir verwenden [pgx](https://github.com/jackc/pgx) als Postgres-Datenbank/Sql-Treiber, der standardmäßig den vorbereiteten Anweisungs-Cache ermöglicht, um es zu deaktivieren:

```go
// https://github.com/go-gorm/postgres
db, err := gorm.Open(postgres.New(postgres.Config{
  DSN: "user=gorm password=gorm dbname=gorm port=9920 sslmode=disable TimeZone=Asia/Shanghai",
  PreferSimpleProtocol: true, // deaktiviert die implizit vorbereitete Anweisungsnutzung
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

**HINWEIS:** Sie können auch `file::memory:?cache=shared` verwenden, anstelle eines Pfades zu einer Datei. Dis wird SQLite anweisen eine Temporäre Datenbank im Systemspeicher anzulegen. (Siehe [SQLite-Dokumentation](https://www.sqlite.org/inmemorydb.html) hierfür)

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

Microsoft bietet [eine Anleitung](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/) für die Verwendung von SQL Server mit Go (und GORM).

## Verbindungspool

GORM benutzt \[database/sql\]((https://pkg.go.dev/database/sql), um den Verbindungspool zu pflegen

```go
sqlDB, err := db.DB()

// SetMaxIdleConns legt die maximale Anzahl von Verbindungen im Pool der Leerlaufverbindung fest.
sqlDB.SetMaxIdleConns(10)

// SetMaxOpenConns sets the maximum number of open connections to the database.
sqlDB.SetMaxOpenConns(100)

// SetConnMaxLifetime legt die maximale Zeit fest, die eine Verbindung wiederverwendet werden kann.
sqlDB.SetConnMaxLifetime(time.Hour)
```

[Allgemeine Schnittstelle](generic_interface.html) für Details anzeigen

## Unsupported Databases

Einige Datenbanken können mit dem `mysql` oder `postgres` Dialekt kompatibel sein, in diesem Fall können Sie einfach den Dialekt für diese Datenbanken verwenden.

Für andere, [wir sind froh um eigen kreierte Treiber, pull request welcome!](write_driver.html)
