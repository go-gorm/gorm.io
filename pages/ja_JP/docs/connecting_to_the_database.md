---
title: Connecting to database
layout: page
---
## データベースへの接続

データベースに接続するには、最初にデータベースドライバーをインポートする必要があります。例：

```go
import _ "github.com/go-sql-driver/mysql"
```

GORMには各ドライバーをラップしたものがあり、インポートパスは記憶しやすくなっていて、mysqlドライバーはこのようにインポートできます。

```go
import _ "github.com/jinzhu/gorm/dialects/mysql"
// import _ "github.com/jinzhu/gorm/dialects/postgres"
// import _ "github.com/jinzhu/gorm/dialects/sqlite"
// import _ "github.com/jinzhu/gorm/dialects/mssql"
```

## サポートされているデータベース

### MySQL

**注意:** `time.Time`を正しく扱うためには、`parseTime`をパラメータに含める必要があります。 ([それ以外にサポートされているパラメータ](https://github.com/go-sql-driver/mysql#parameters))

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

### SQL Server

[SQL Serverで始める場合](https://www.microsoft.com/en-us/sql-server/developer-get-started/go)、[Mac](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/go/mac/)、[Linux](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/go/ubuntu/)上のDockerを使って起動できます。

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

GORMは公式に上記4つのデータベースをサポートしていて、サポート外のデータベースの方言も書くことができます。[GORM Dialects](/docs/dialects.html)を参照してください。