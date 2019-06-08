---
title: Подключение к базе данных
layout: страница
---

# Подключение к базе данных

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

## MySQL

**ПРИМЕЧАНИЕ:** Для правильной работы `time.Time`, вам нужно включить `parseTime` в качестве параметра. ([Больше поддерживаемых параметров](https://github.com/go-sql-driver/mysql#parameters))

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

**ПРИМЕЧАНИЕ:** Вы также можете использовать `:memory:` для подключения, которое будет использовать sqlite во временной системной памяти. Это особенно полезно при написании тестов для вашего приложения с использованием GORM.

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

## MS SQL Server

[Начните с MS SQL Server](https://www.microsoft.com/en-us/sql-server/developer-get-started/go), он может работать на вашем [Mac](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/go/mac/), [Linux](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/go/ubuntu/) с использованием Docker

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

## Написание Диалекта для неподдерживаемых баз данных

GORM официально поддерживает вышеперечисленные базы данных, но вы можете написать диалект для неподдерживаемых баз данных.

Чтобы написать свой собственный диалект, обратитесь к: <https://github.com/jinzhu/gorm/blob/master/dialect.go>
