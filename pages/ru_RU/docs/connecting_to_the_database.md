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

**ПРИМЕЧАНИЕ:** Вы также можете использовать `:memory:` вместо пути к файлу. Это скажет sqlite использовать временную базу данных в системной памяти. Это особенно полезно при написании тестов для вашего приложения с использованием GORM, но также может использоваться как база данных.

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

[Начните с MS SQL Server](https://www.microsoft.com/en-us/sql-server/developer-get-started/go), он может работать на вашем [Mac](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/go/mac/), [Linux](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/go/ubuntu/) с использованием Docker

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

GORM официально поддерживает более четырех баз данных, вы можете написать диалекты для неподдерживаемых баз данных, см. [GORM Диалекты](/docs/dialects.html)
