---
title: Conectando ao banco de dados
layout: page
---

GORM officially supports the databases MySQL, PostgreSQL, GaussDB, SQLite, SQL Server TiDB, and Oracle Database

## MySQL

```go
import (
  "gorm.io/driver/mysql"
  "gorm.io/gorm"
)

func main() {
  // referencia https://github.com/go-sql-driver/mysql#dsn-data-source-name para mais detalhes
  dsn := "user:pass(127.0.0.1:3306)/dbname?charset=utf8mb4&parseTime=True&loc=Local"
  db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
}
```

{% note warn %}
**NOTA:** Para manipular `time.Time` corretamente, você precisa incluir `parseTime` como parâmetro. ([mais parâmetros](https://github.com/go-sql-driver/mysql#parameters)) Para suportar totalmente a codificação UTF-8, você precisa alterar o `charset=utf8` para `charset=utf8mb4`. Veja [este artigo](https://mathiasbynens.be/notes/mysql-utf8mb4) para uma explicação mais detalhada
{% endnote %}

O MySQL Driver fornece [algumas configurações avançadas](https://github.com/go-gorm/mysql) que podem ser utilizadas durante a inicialização, por exemplo:

```go
db, err := gorm.Open(mysql.New(mysql.Config{
  DSN: "gorm:gorm@tcp(127.0.0.1:3306)/gorm?charset=utf8&parseTime=True&loc=Local", // Nome base de dados.
  DefaultStringSize: 256, // tamanha padrao para campo string.
  DisableDatetimePrecision: true, //  desabilita precisão datetime , não suportado antes de MySQL 5.6.
  DontSupportRenameIndex: true, // drop & create ao renomear index, renomear index não suportado antes de MySQL 6.7,MariaDB.
  DontSupportRenameColumn: true, // `alterar` ao renomear coluna, renomear coluna não suportado antes de MySQL 8,MariaDB.
  SkipInitializeWithVersion: false, // Auto-configuração baseada na atual versaro do MySQL.
}), &gorm.Config{})
```

### Driver Customizado

GORM permite a customização do driver de MySQL, com a opção `DriverName` por exemplo:

```go
import (
  _ "example.com/my_mysql_driver"
  "gorm.io/driver/mysql"
  "gorm.io/gorm"
)

db, err := gorm.Open(mysql.New(mysql.Config{
  DriverName: "my_mysql_driver",
  DSN: "gorm:gorm@tcp(localhost:9910)/gorm?charset=utf8&parseTime=True&loc=Local", // Nome base de dados, referencia https://github.com/go-sql-driver/mysql#dsn-data-source-name
}), &gorm.Config{})
```

### Conexão com base de dados existente

GORM permite inicializar `*gorm.DB` com uma conexão de base de dados existente

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

Nós estamos utilizando [pgx](https://github.com/jackc/pgx) como driver para base de dados postgres, isso permite preparar o cache da declaração por padrão, para desabilita-lo:

```go
// https://github.com/go-gorm/postgres
db, err := gorm.Open(postgres.New(postgres.Config{
  DSN: "user=gorm password=gorm dbname=gorm port=9920 sslmode=disable TimeZone=Asia/Shanghai",
  PreferSimpleProtocol: true, //  desabilita o uso implícito de  declaração Preparada.
}), &gorm.Config{})
```

### Personalizar Driver

GORM allows to customize the PostgreSQL driver with the `DriverName` option, for example:

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

GORM allows to initialize `*gorm.DB` with an existing database connection

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

## GaussDB

```go
import (
  "gorm.io/driver/gaussdb"
  "gorm.io/gorm"
)

dsn := "host=localhost user=gorm password=gorm dbname=gorm port=8000 sslmode=disable TimeZone=Asia/Shanghai"
db, err := gorm.Open(gaussdb.Open(dsn), &gorm.Config{})
```

We are using [gaussdb-go](https://github.com/HuaweiCloudDeveloper/gaussdb-go) as gaussdb's database/sql driver, it enables prepared statement cache by default, to disable it:

```go
// https://github.com/go-gorm/gaussdb
db, err := gorm.Open(gaussdb.New(gaussdb.Config{
  DSN: "user=gorm password=gorm dbname=gorm port=8000 sslmode=disable TimeZone=Asia/Shanghai",
  PreferSimpleProtocol: true, // disables implicit prepared statement usage
}), &gorm.Config{})
```

### Customize Driver

GORM allows to customize the GaussDB driver with the `DriverName` option, for example:

```go
import (
  _ "github.com/GoogleCloudPlatform/cloudsql-proxy/proxy/dialers/gaussdb"
  "gorm.io/gorm"
)

db, err := gorm.Open(gaussdb.New(gaussdb.Config{
  DriverName: "cloudsqlgaussdb",
  DSN: "host=project:region:instance user=gaussdb dbname=gaussdb password=password sslmode=disable",
})
```

### Existing database connection

GORM allows to initialize `*gorm.DB` with an existing database connection

```go
import (
  "database/sql"
  "gorm.io/driver/gaussdb"
  "gorm.io/gorm"
)

sqlDB, err := sql.Open("gaussdbgo", "mydb_dsn")
gormDB, err := gorm.Open(gaussdb.New(gaussdb.Config{
  Conn: sqlDB,
}), &gorm.Config{})
```
## Oracle Database
The GORM Driver for Oracle provides support for Oracle databases, enabling full compatibility with GORM's ORM capabilities. It is built on top of the [Go Driver for Oracle (Godror)](https://github.com/godror/godror) and supports key features such as auto migrations, associations, transactions, and advanced querying.

### Prerequisite: Install Instant Client
To use ODPI-C with Godror, you’ll need to install the Oracle Instant Client on your system.

Follow the steps on [this page](https://odpi-c.readthedocs.io/en/latest/user_guide/installation.html) to complete the installation.

After that, use a logfmt-encoded parameter list to specify the instant client directory in the `dataSourceName` when you connect to the database. For example:

```go
dsn := `user="scott" password="tiger" 
        connectString="[host]:[port]/cdb1_pdb1.regress.rdbms.dev.us.oracle.com"
        libDir="/Path/to/your/instantclient_23_8"`
```
### Getting Started
```go
import (
  "github.com/oracle-samples/gorm-oracle/oracle"
  "gorm.io/gorm"
)

dsn := `user="scott" password="tiger"
        connectString="[host]:[port]/cdb1_pdb1.regress.rdbms.dev.us.oracle.com"
        libDir="/Path/to/your/instantclient_23_8"`
db, err := gorm.Open(oracle.Open(dsn), &gorm.Config{})
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
**NOTE:** You can also use `file::memory:?cache=shared` instead of a path to a file. This will tell SQLite to use a temporary database in system memory. (See [SQLite docs](https://www.sqlite.org/inmemorydb.html) for this)
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

TiDB é compatível com o protocolo MySQL. Você pode seguir a parte [MySQL](#mysql) para criar uma conexão com TiDB.

Há alguns pontos dignos de nota para o TiDB:

- Você pode usar a tag `gorm:"primaryKey;default:auto_random()"` para usar o recurso [`AUTO_RANDOM`](https://docs.pingcap.com/tidb/stable/auto-random) para TiDB.
- TiDB supported [`SAVEPOINT`](https://docs.pingcap.com/tidb/stable/sql-statement-savepoint) from `v6.2.0`, please notice the version of TiDB when you use this feature.
- TiDB supported [`FOREIGN KEY`](https://docs.pingcap.com/tidb/dev/foreign-key) from `v6.6.0`, please notice the version of TiDB when you use this feature.

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

## Conjunto de Conexão

GORM usando [database/sql](https://pkg.go.dev/database/sql) para manter o *pool* de conexão

```go
sqlDB, err := db.DB()

// SetMaxIdleConns sets the maximum number of connections in the idle connection pool.
sqlDB.SetMaxIdleConns(10)

// SetMaxOpenConns sets the maximum number of open connections to the database.
sqlDB.SetMaxOpenConns(100)

// SetConnMaxLifetime sets the maximum amount of time a connection may be reused.
sqlDB.SetConnMaxLifetime(time.Hour)
```

Refer [Generic Interface](generic_interface.html) for details

## Bancos de dados não suportados

Alguns bancos de dados podem ser compatíveis com o dialeto do `mysql` ou `postgres`, nesse caso seria possível usar o dialeto para essas bases de dados.

Para outros, [você é encorajado a fazer um driver, seu pull request será bem vindo!](write_driver.html)
