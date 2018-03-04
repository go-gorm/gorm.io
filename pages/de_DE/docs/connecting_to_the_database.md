---
title: Verbindung zur Datenbank
layout: seite
---
## Verbindung zur Datenbank

Um die Verbindung zu einer Datenbank, müssen Sie zuerst den Datenbank-Treiber importieren. Zum Beispiel:

```go
importieren Sie _ "github.com/go-sql-driver/mysql"
```

GORM hat einige Treiber, um leichter zu ihrer Importpfad erinnern, so dass Sie den Mysql-Treiber mit importieren könnte gewickelt

```go
_ "github.com/jinzhu/gorm/dialects/mysql" importieren / / import _ "github.com/jinzhu/gorm/dialects/postgres" / / import _ "github.com/jinzhu/gorm/dialects/sqlite" / / import _ "github.com/jinzhu/gorm/dialects/mssql"
```

## Unterstützte Datenbanken

### MySQL

**NOTE:** In order to handle `time.Time` correctly, you need to include `parseTime` as a parameter. ([More supported parameters](https://github.com/go-sql-driver/mysql#parameters))

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

### Fehlerbehebung

[Get started with SQL Server](https://www.microsoft.com/en-us/sql-server/developer-get-started/go), it can running on your [Mac](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/go/mac/), [Linux](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/go/ubuntu/) with Docker

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

## Unterstützte Datenbanken

GORM officially supports above four databases, you could write dialects for unsupported databases, refer [GORM Dialects](/docs/dialects.html)