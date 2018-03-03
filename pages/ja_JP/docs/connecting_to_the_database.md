---
title: データベースへの接続
layout: ページ
---
## データベースへの接続

データベースに接続するために最初にデータベースのドライバーをインポートする必要があります。例えば：

```go
import _ "github.com/go-sql-driver/mysql"
```

GORM has wrapped some drivers, to make easier to remember their import path, so you could import the mysql driver with

```go
import _ "github.com/jinzhu/gorm/dialects/mysql"
// import _ "github.com/jinzhu/gorm/dialects/postgres"
// import _ "github.com/jinzhu/gorm/dialects/sqlite"
// import _ "github.com/jinzhu/gorm/dialects/mssql"
```

## データベースをサポート

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

### SQL サーバー

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

## データベースをサポート

GORM officially supports above four databases, you could write dialects for unsupported databases, refer [GORM Dialects](/docs/dialects.html)