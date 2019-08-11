---
title: データベースへの接続
layout: page
---

## データベースへの接続

データベースに接続するには、まずデータベースのドライバーをImportする必要があります。

```go
import _ "github.com/go-sql-driver/mysql"
```

GORMには各ドライバーのImportを楽にするためのラッパーがいくつか用意されています。例えばMySQLドライバーをImportする場合は、下記のように書けます。

```go
import _ "github.com/jinzhu/gorm/dialects/mysql"
// import _ "github.com/jinzhu/gorm/dialects/postgres"
// import _ "github.com/jinzhu/gorm/dialects/sqlite"
// import _ "github.com/jinzhu/gorm/dialects/mssql"
```

## サポートされているデータベース

### MySQL

**注意**

In order to handle `time.Time` correctly, you need to include `parseTime` as a parameter. ([More supported parameters](https://github.com/go-sql-driver/mysql#parameters))

In order to fully support UTF-8 encoding, you need to change `charset=utf8` to `charset=utf8mb4`. See this [article](https://mathiasbynens.be/notes/mysql-utf8mb4) for a detailed explanation.

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

**NOTE:** You can also use `:memory:` instead of a path to a file. This will tell sqlite to use a temporary database in system memory. This is especially useful when writing tests for your application against GORM, your tests to hit an actual database, but also be performant as the database is located in memory.

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

### SQL Server

[Get started with SQL Server](https://www.microsoft.com/en-us/sql-server/developer-get-started/go), it can run on your [Mac](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/go/mac/), [Linux](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/go/ubuntu/) with Docker

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

## サポートされていないデータベース

GORM officially supports above four databases, you could write dialects for unsupported databases, refer [GORM Dialects](/docs/dialects.html)
