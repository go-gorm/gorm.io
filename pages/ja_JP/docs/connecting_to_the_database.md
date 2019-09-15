---
title: データベースへの接続
layout: page
---

## データベースへの接続

データベースに接続するには、まずデータベースのドライバーをImportする必要があります。

```go
import _ "github.com/go-sql-driver/mysql"
```

GORMには各ドライバーのImportを楽にするためのラッパーがいくつか用意されています。例えばMySQLドライバーをImportする場合は、下記のように書けます。

```go
import _ "github.com/jinzhu/gorm/dialects/mysql"
// import _ "github.com/jinzhu/gorm/dialects/postgres"
// import _ "github.com/jinzhu/gorm/dialects/sqlite"
// import _ "github.com/jinzhu/gorm/dialects/mssql"
```

## サポートされているデータベース

### MySQL

**注意**

`time.Time`を正しく扱うため、`parseTime`をパラメータとして渡してあげる必要があります。 ([対応している他のパラメータ](https://github.com/go-sql-driver/mysql#parameters))

UTF-8の完全な対応のため、`charset=utf8`を`charset=utf8mb4`に変更する必要があります。 詳しくは [こちらの記事](https://mathiasbynens.be/notes/mysql-utf8mb4) を参照してください。

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

**NOTE:**パスの代わりに`:memory:`の指定も可能です。 この場合、sqliteに対してシステムのメモリ上に一時的なデータベースを利用するように指定します。 GORMの機能を使ってメモリー上の実際のDBを叩くことになるので、テストの時に便利です。

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

[Get started with SQL Server](https://www.microsoft.com/en-us/sql-server/developer-get-started/go), Dockerを使って[Mac](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/go/mac/)や[Linux](https://sqlchoice.azurewebsites.net/en-us/sql-server/developer-get-started/go/ubuntu/)で実行することもできます。

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

GORMは上記4つのデータベースを公式サポートしています。サポートされていないデータベース用にDialectを書くことも可能です。[GORM Dialects](/docs/dialects.html)を参照してください。