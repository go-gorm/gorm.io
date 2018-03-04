---
title: Connecting to the database
layout: page
---
# Conectándose a la Base de Datos

Para conectarse a una base de datos, necesita importar primero el controlador de la base de datos. Por ejemplo:

```go
import _ "github.com/go-sql-driver/mysql"
```

GORM ha envuelto algunos controladores, para que sea más fácil recordar su ruta de importación, por lo que podría importar el controlador de mysql con

```go
import _ "github.com/jinzhu/gorm/dialects/mysql"
// import _ "github.com/jinzhu/gorm/dialects/postgres"
// import _ "github.com/jinzhu/gorm/dialects/sqlite"
// import _ "github.com/jinzhu/gorm/dialects/mssql"
```

## MySQL

**NOTA:** para manejar `time.Time`, necesita incluir `parseTime` como parámetro. ([Más parámetros compatibles](https://github.com/go-sql-driver/mysql#parameters))

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

## SQL Server

[Comenzando con SQL Server](https://www.microsoft.com/en-us/sql-server/developer-get-started/go), puede ejecutarse en su [Mac](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/go/mac/), [Linux](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/go/ubuntu/) con Docker

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

## Escribir Dialectos para bases de datos no compatibles

GORM admite oficialmente las bases de datos anteriores, pero puede escribir un dialecto para bases de datos no compatibles.

Para escribir su propio dialecto, consulte: <https://github.com/jinzhu/gorm/blob/master/dialect.go>