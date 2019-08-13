---
title: 连接数据库
layout: page
---

# 连接数据库

要连接到数据库，首先应该导入数据库驱动．例如：

```go
import _ "github.com/go-sql-driver/mysql"
```

GORM 已经包装了一些驱动，以便更容易的记住导入路径，所以你可以这样导入 mysql 的驱动：

```go
import _ "github.com/jinzhu/gorm/dialects/mysql"
// import _ "github.com/jinzhu/gorm/dialects/postgres"
// import _ "github.com/jinzhu/gorm/dialects/sqlite"
// import _ "github.com/jinzhu/gorm/dialects/mssql"
```

## MySQL

**注意:**为了正确处理 `time.Time `, 您需要添加 `parseTime` 参数。 ([更多支持的参数](https://github.com/go-sql-driver/mysql#parameters))

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

**注意：** 你也可以使用`:memory:` 连接数据库，这将在临时内存中使用 sqlite 当您针对 GORM 编写应用程序测试时，这尤其有用。

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

[通过 SQL Server 开始使用](https://www.microsoft.com/en-us/sql-server/developer-get-started/go),它可以运行在有 Docker 环境的 [Mac](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/go/mac/), [Linux](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/go/ubuntu/) 上。

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

## 为不支持的数据库编写方言

GORM 官方支持上述四个数据库，但您可以为不受支持的数据库编写方言（Dialects）

编写你自己的方言，请参阅： <https://github.com/jinzhu/gorm/blob/master/dialect.go>