---
title: Connecting to database
layout: page
---

## Conexión a la base de datos

Para conectarse a la base de datos, debes importar el driver de la base de datos primero. Por ejemplo:

```go
import _ "github.com/go-sql-driver/mysql"
```

GORM ha creado algunos drivers para facilitar recordar la ruta de importación. Así puedes importar el driver de mysql con:

```go
import _ "github.com/jinzhu/gorm/dialects/mysql" // import _ "github.com/jinzhu/gorm/dialects/postgres" // import _ "github.com/jinzhu/gorm/dialects/sqlite" // import _ "github.com/jinzhu/gorm/dialects/mssql"
```

## Bases de Datos Compatibles

### MySQL

**Nota:**

Para poder manejar `time.Time` correctamente, debes incluir `parseTime` como parámetro. ([Mas parámetros soportados](https://github.com/go-sql-driver/mysql#parameters))

Para poder soportar la codificación UTF-8, debes cambiar `charset=utf8` a `charset=utf8mb4`. Mira este [articulo](https://mathiasbynens.be/notes/mysql-utf8mb4) para una explicacion mas detallada.

```go
import (   "github.com/jinzhu/gorm"   _ "github.com/jinzhu/gorm/dialects/mysql" ) func main() {   db, err := gorm.Open("mysql", "user:password@/dbname?charset=utf8&parseTime=True&loc=Local")   defer db.Close() }
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

## Bases de Datos no Compatibles

GORM officially supports above four databases, you could write dialects for unsupported databases, refer [GORM Dialects](dialects.html)