---
title: 连接数据库
layout: page
---

## 连接数据库

想要连接数据库，你需要先导入对应数据库的驱动，比如：

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

## 所支持的数据库

### MySQL

**注意：**

想要能正确的处理 `time.Time`，你需要添加 `parseTime` 参数。 ([更多支持的参数](https://github. com/go-sql-driver/mysql#parameters))

想要完全的支持 UTF-8 编码，你需要修改`charset=utf8` 为 `charset=utf8mb4`。 详情请查看 [utf8mb4](https://mathiasbynens.be/notes/mysql-utf8mb4).

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

如果你想指定主机，你需要使用 `()`. 例如:

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

**注意:** 你也可以使用 `:memory:` 替换一个文件路径。 这会告诉 sqlite 使用内存作为一个临时数据。 当你针对 GORM 应用进行测试时，这特别有用，因为你的测试需要一个真正的数据库，并且该数据库位于内存中，性能也很好。

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

[Get started with SQL Server](https://www.microsoft.com/en-us/sql-server/developer-get-started/go), 它可以运行在你的 [Mac](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/go/mac/)、[Linux](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/go/ubuntu/) 和 Docker

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

## 不支持的数据库

GORM 官方支持上述四个数据库, 您可以为不受支持的数据库编写方言(Dialects), 请参阅 [GORM Dialects ](/docs/dialects.html)