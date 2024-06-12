---
title: 데이터베이스에 연결하기
layout: page
---

GORM은 공식적으로 MYSQL, PostreSQL, SQLite, SQL Server 그리고 TiDB를 지원합니다.

## MySQL

```go
import (
  "gorm.io/driver/mysql"
  "gorm.io/gorm"
)

func main() {
  // refer https://github.com/go-sql-driver/mysql#dsn-data-source-name for details
  dsn := "user:pass@tcp(127.0.0.1:3306)/dbname?charset=utf8mb4&parseTime=True&loc=Local"
  db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
}
```

{% note warn %}
**주의할점**: `time.Time` 을 정확하게 다루기 위하여 먼저 `parseTime`을 인자로서 포함해주세요. ([더 많은 인자를 고려하기](https://github.com/go-sql-driver/mysql#parameters)) UTF-8 인코딩을 완전히 지원하기 위하여 `charset=utf8`을 `charset=utf8mb4` 로 바꿔주세요. 해당 [기사](https://mathiasbynens.be/notes/mysql-utf8mb4)를 통해 더욱 자세한 사항을 확인할 수 있습니다.
{% endnote %}

MySQL 드라이버는 다음과 같이 생성시 사용될 수 있는 [향상된 추가 설정](https://github.com/go-gorm/mysql)을 지원합니다. 예시:

```go
db, err := gorm.Open(mysql.New(mysql.Config{
  DSN: "gorm:gorm@tcp(127.0.0.1:3306)/gorm?charset=utf8&parseTime=True&loc=Local", // data source name
  DefaultStringSize: 256, // default size for string fields
  DisableDatetimePrecision: true, // disable datetime precision, which not supported before MySQL 5.6
  DontSupportRenameIndex: true, // drop & create when rename index, rename index not supported before MySQL 5.7, MariaDB
  DontSupportRenameColumn: true, // `change` when rename column, rename column not supported before MySQL 8, MariaDB
  SkipInitializeWithVersion: false, // auto configure based on currently MySQL version
}), &gorm.Config{})
```

### Customize Driver

GORM은 `드라이버 이름` 옵션을 통해 MySQL 드라이버를 Customize하는 것을 지원합니다. 예시:

```go
import (
  _ "example.com/my_mysql_driver"
  "gorm.io/driver/mysql"
  "gorm.io/gorm"
)

db, err := gorm.Open(mysql.New(mysql.Config{
  DriverName: "my_mysql_driver",
  DSN: "gorm:gorm@tcp(localhost:9910)/gorm?charset=utf8&parseTime=True&loc=Local", // data source name, refer https://github.com/go-sql-driver/mysql#dsn-data-source-name
}), &gorm.Config{})
```

### Existing database connection

GORM은 `*gorm.DB`을 생성시 이미 존재하는 데이터베이스 connection을 바탕으로 생성이 가능합니다.

```go
import (
  "database/sql"
  "gorm.io/driver/mysql"
  "gorm.io/gorm"
)

sqlDB, err := sql.Open("mysql", "mydb_dsn")
gormDB, err := gorm.Open(mysql.New(mysql.Config{
  Conn: sqlDB,
}), &gorm.Config{})
```

## PostgreSQL

```go
import (
  "gorm.io/driver/postgres"
  "gorm.io/gorm"
)

dsn := "host=localhost user=gorm password=gorm dbname=gorm port=9920 sslmode=disable TimeZone=Asia/Shanghai"
db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
```

We are using [pgx](https://github.com/jackc/pgx) as postgres's database/sql driver, it enables prepared statement cache by default, to disable it:

```go
// https://github.com/go-gorm/postgres
db, err := gorm.Open(postgres.New(postgres.Config{
  DSN: "user=gorm password=gorm dbname=gorm port=9920 sslmode=disable TimeZone=Asia/Shanghai",
  PreferSimpleProtocol: true, // disables implicit prepared statement usage
}), &gorm.Config{})
```

### Customize Driver

`드라이버 이름` 옵션을 통해 PostgreSQL 드라이버를 Customize하는 것을 지원합니다. 예시:

```go
import (
  _ "github.com/GoogleCloudPlatform/cloudsql-proxy/proxy/dialers/postgres"
  "gorm.io/gorm"
)

db, err := gorm.Open(postgres.New(postgres.Config{
  DriverName: "cloudsqlpostgres",
  DSN: "host=project:region:instance user=postgres dbname=postgres password=password sslmode=disable",
})
```

### Existing database connection

GORM은 `*gorm.DB`를 생성시 이미 존재하는 데이터베이스 connection을 바탕으로 생성이 가능합니다.

```go
import (
  "database/sql"
  "gorm.io/driver/postgres"
  "gorm.io/gorm"
)

sqlDB, err := sql.Open("pgx", "mydb_dsn")
gormDB, err := gorm.Open(postgres.New(postgres.Config{
  Conn: sqlDB,
}), &gorm.Config{})
```

## SQLite

```go
import (
  "gorm.io/driver/sqlite" // Sqlite driver based on CGO
  // "github.com/glebarez/sqlite" // Pure go SQLite driver, checkout https://github.com/glebarez/sqlite for details
  "gorm.io/gorm"
)

// github.com/mattn/go-sqlite3
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{})
```

{% note warn %}
**NOTE:** You can also use `file::memory:?cache=shared` instead of a path to a file. 이 경우 SQLite는 시스템의 메모리에 있는 임시적인 DataBase를 활용할 것 입니다. ([SQLite docs](https://www.sqlite.org/inmemorydb.html)를 참고하세요)
{% endnote %}

## SQL Server

```go
import (
  "gorm.io/driver/sqlserver"
  "gorm.io/gorm"
)

// github.com/denisenkom/go-mssqldb
dsn := "sqlserver://gorm:LoremIpsum86@localhost:9930?database=gorm"
db, err := gorm.Open(sqlserver.Open(dsn), &gorm.Config{})
```

## TiDB

TiDB는 MySQL 프로토콜과 호환됩니다. [MySQL](#mysql)파트와 동일한 방법으로 TiDB와의 연결을 설정할 수 있습니다.

TiDB사용시 몇 가지 참고할 점:

- `gorm:"primaryKey;default:auto_random()"` 태그를 통해 TiDB의 [`AUTO_RANDOM`](https://docs.pingcap.com/tidb/stable/auto-random)기능을 사용할 수 있습니다.
- TiDB는 `v6.2.0`버전부터 [`SAVEPOINT`](https://docs.pingcap.com/tidb/stable/sql-statement-savepoint)기능을 지원합니다, 사용하시는 TiDB 버전을 참고하시어 해당 기능을 사용해 주세요.
- TiDB는 `v6.6.0`버전부터 [`FOREIGN KEY`](https://docs.pingcap.com/tidb/dev/foreign-key)기능을 지원합니다, 사용하시는 TiDB버전을 참고하시어 해당 기능을 사용해주세요.

```go
import (
  "fmt"
  "gorm.io/driver/mysql"
  "gorm.io/gorm"
)

type Product struct {
  ID    uint `gorm:"primaryKey;default:auto_random()"`
  Code  string
  Price uint
}

func main() {
  db, err := gorm.Open(mysql.Open("root:@tcp(127.0.0.1:4000)/test"), &gorm.Config{})
  if err != nil {
    panic("failed to connect database")
  }

  db.AutoMigrate(&Product{})

  insertProduct := &Product{Code: "D42", Price: 100}

  db.Create(insertProduct)
  fmt.Printf("insert ID: %d, Code: %s, Price: %d\n",
    insertProduct.ID, insertProduct.Code, insertProduct.Price)

  readProduct := &Product{}
  db.First(&readProduct, "code = ?", "D42") // find product with code D42

  fmt.Printf("read ID: %d, Code: %s, Price: %d\n",
    readProduct.ID, readProduct.Code, readProduct.Price)
}
```

## Clickhouse

https://github.com/go-gorm/clickhouse

```go
import (
  "gorm.io/driver/clickhouse"
  "gorm.io/gorm"
)

func main() {
  dsn := "tcp://localhost:9000?database=gorm&username=gorm&password=gorm&read_timeout=10&write_timeout=20"
  db, err := gorm.Open(clickhouse.Open(dsn), &gorm.Config{})

  // Auto Migrate
  db.AutoMigrate(&User{})
  // Set table options
  db.Set("gorm:table_options", "ENGINE=Distributed(cluster, default, hits)").AutoMigrate(&User{})

  // Insert
  db.Create(&user)

  // Select
  db.Find(&user, "id = ?", 10)

  // Batch Insert
  var users = []User{user1, user2, user3}
  db.Create(&users)
  // ...
}
```

## 커넥션 풀

GORM은 [database/sql](https://pkg.go.dev/database/sql)을 사용하여 커넥션 풀을 유지합니다.

```go
sqlDB, err := db.DB()

// SetMaxIdleConns sets the maximum number of connections in the idle connection pool.
sqlDB.SetMaxIdleConns(10)

// SetMaxOpenConns sets the maximum number of open connections to the database.
sqlDB.SetMaxOpenConns(100)

// SetConnMaxLifetime sets the maximum amount of time a connection may be reused.
sqlDB.SetConnMaxLifetime(time.Hour)
```

[Generic Interface](generic_interface.html)를 참조하여 더욱 자세한 사항을 알아보세요.

## 지원되지 않는 데이터베이스

특정 데이터베이스는 `mysql`이나 `postgres`의 Sql문법과 호환될 수 있습니다. 어떤 경우라도, 해당 데이터 베이스 문법을 활용하여 Gorm을 사용할 수 있습니다.

[데이터베이스 드라이버를 만드셨거나, 혹은 다른 이유라도 pull request는 환영입니다!](write_driver.html)
