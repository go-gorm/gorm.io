---
title: Подключение к базе данных
layout: страница
---

## Подключение к базе данных

Для подключения к базе данных необходимо сначала импортировать драйвер базы данных. Например:

```go
import _ "github.com/go-sql-driver/mysql"
```

GORM содержит некоторые драйверы, чтобы облегчить запоминание пути импорта. Так что вы можете импортировать драйвер mysql с помощью:

```go
import _ "github.com/jinzhu/gorm/dialects/mysql"
// import _ "github.com/jinzhu/gorm/dialects/postgres"
// import _ "github.com/jinzhu/gorm/dialects/sqlite"
// import _ "github.com/jinzhu/gorm/dialects/mssql"
```

## Поддерживаемые базы данных

### MySQL

**ПРИМЕЧАНИЕ:**

Для правильной работы `time.Time`, вам нужно включить `parseTime` в качестве параметра. ([Дополнительные поддерживаемые параметры](https://github.com/go-sql-driver/mysql#parameters))

Чтобы полностью поддержать кодировку UTF-8, вам нужно изменить `charset=utf8` на `charset=utf8mb4`. Посмотрите эту [статью](https://mathiasbynens.be/notes/mysql-utf8mb4) для подробностей.

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

### MS SQL Server

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

## Неподдерживаемые базы данных

GORM officially supports above four databases, you could write dialects for unsupported databases, refer [GORM Dialects](/docs/dialects.html)