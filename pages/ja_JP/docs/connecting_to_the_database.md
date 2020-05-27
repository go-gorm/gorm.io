---
title: Connecting to a Database
layout: page
---

## Importing a Driver

In order to connect to a database, you need to import its driver first.

GORM wraps the drivers for the officially supported databases.

```go
import _ "github.com/jinzhu/gorm/dialects/mysql"
// import _ "github.com/jinzhu/gorm/dialects/postgres"
// import _ "github.com/jinzhu/gorm/dialects/sqlite"
// import _ "github.com/jinzhu/gorm/dialects/mssql"
```

You can import other drivers in the same way.

```go
import _ "github.com/go-sql-driver/mysql"
```

## サポートされているデータベース

### MySQL

**NOTE:**

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

If you want to specify the host, you need to use `()`. Example:

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

### SQLite3

**NOTE:** You can also use `:memory:` instead of a path to a file. This will tell SQLite to use a temporary database in system memory. (See [SQLite docs](https://www.sqlite.org/inmemorydb.html) for this.)

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

Microsoft offers [a guide](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/) for using SQL Server with Go (and GORM).

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

GORM officially supports the databases listed above, but you can [write GORM dialects](dialects.html) for unsupported databases.