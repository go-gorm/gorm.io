---
title: एक डेटाबेस से जुड़ना //Connecting to a Database
layout: पृष्ठ
---

GORM officially supports the databases MySQL, PostgreSQL, SQLite, SQL Server, and TiDB

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
**ध्यान दें:** `time.Time` को सही तरीके से हैंडल करने के लिए, आपको `parseTime` को एक पैरामीटर के रूप में शामिल करना होगा। ([अधिक पैरामीटर](https://github.com/go-sql-driver/mysql#parameters)) UTF-8 एन्कोडिंग का पूर्ण समर्थन करने के लिए, आपको `charset=utf8` को `charset=utf8mb4` में बदलना होगा। विस्तृत व्याख्या के लिए [यह लेख](https://mathiasbynens.be/notes/mysql-utf8mb4) देखें
{% endnote %}

MySQL ड्राइवर [कुछ advanced कॉन्फ़िगरेशन](https://github.com/go-gorm/mysql) प्रदान करता है, जिसका उपयोग initialization के दौरान किया जा सकता है, उदाहरण के लिए:

```go
db, err := gorm.Open(mysql.New(mysql.Config{
  DSN: "gorm:gorm@tcp(127.0.0.1:3306)/gorm?charset=utf8&parseTime=True&loc=Local", // data source name //डेटा स्रोत का नाम
  DefaultStringSize: 256, // default size for string fields //स्ट्रिंग फ़ील्ड के लिए डिफ़ॉल्ट आकार
  DisableDatetimePrecision: true, // disable datetime precision, which not supported before MySQL 5.6 /डेटाटाइम परिशुद्धता अक्षम करें, जो MySQL 5.6 से पहले समर्थित नहीं है
  DontSupportRenameIndex: true, // drop & create when rename index, rename index not supported before MySQL 5.7, MariaDB //
निर्दिष्ट का नाम बदलने पर बनाएँ, MySQL 5.7, MariaDB से पहले संगति का नाम परिवर्तन नहीं होता है
  DontSupportRenameColumn: true, // `change` when rename column, rename column not supported before MySQL 8, MariaDB 
// // `परिवर्तन` जब स्तंभ का नाम बदलें, नाम बदलें कॉलम MySQL 8, MariaDB से पहले समर्थित नहीं है
  SkipInitializeWithVersion: false, // auto configure based on currently MySQL version //वर्तमान में MySQL संस्करण के आधार पर ऑटो कॉन्फ़िगर करें
}), &gorm.Config{})
```

### ड्राइवर को अनुकूलित करें //Customize Driver

GORM MySQL ड्राइवर को `DriverName` विकल्प के साथ अनुकूलित करने की अनुमति देता है, उदाहरण के लिए:

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

### Existing database connection //मौजूदा डेटाबेस कनेक्शन

GORM किसी मौजूदा डेटाबेस कनेक्शन के साथ `*gorm.DB` प्रारंभ करने की अनुमति देता है

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

हम [pgx](https://github.com/jackc/pgx) का उपयोग पोस्टग्रेज के डेटाबेस/एसक्यूएल ड्राइवर के रूप में कर रहे हैं, यह इसे निष्क्रिय करने के लिए डिफ़ॉल्ट रूप से तैयार स्टेटमेंट कैश को सक्षम करता है:

```go
// https://github.com/go-gorm/postgres
db, err := gorm.Open(postgres.New(postgres.Config{
  DSN: "user=gorm password=gorm dbname=gorm port=9920 sslmode=disable TimeZone=Asia/Shanghai",
  PreferSimpleProtocol: true, // disables implicit prepared statement usage
}), &gorm.Config{})
```

### Customize Driver

GORM उदाहरण के लिए, `DriverName` विकल्प के साथ PostgreSQL ड्राइवर को अनुकूलित करने की अनुमति देता है:

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

GORM किसी मौजूदा डेटाबेस कनेक्शन के साथ `*gorm.DB` प्रारंभ करने की अनुमति देता है

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
  "gorm.io/driver/sqlite" // Sqlite driver based on GGO
  // "github.com/glebarez/sqlite" // Pure go SQLite driver, checkout https://github.com/glebarez/sqlite for details
  "gorm.io/gorm"
)

// github.com/mattn/go-sqlite3
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{})
```

{% note warn %}
**ध्यान दें:** आप फ़ाइल के पथ के बजाय `file::memory:?cache=shared` का भी उपयोग कर सकते हैं। यह SQLite को सिस्टम मेमोरी में अस्थायी डेटाबेस का उपयोग करने के लिए कहेगा। (इसके लिए [SQLite डॉक्स](https://www.sqlite.org/inmemorydb.html) देखें)
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

TiDB is compatible with MySQL protocol. You can follow the [MySQL](#mysql) part to create a connection to TiDB.

There are some points noteworthy for TiDB:

- You can use `gorm:"primaryKey;default:auto_random()"` tag to use [`AUTO_RANDOM`](https://docs.pingcap.com/tidb/stable/auto-random) feature for TiDB.
- TiDB doesn't support the foreign key feature yet so far. You can see the TiDB document [MySQL Compatibility](https://docs.pingcap.com/tidb/stable/mysql-compatibility) for more information.
- TiDB supported [`SAVEPOINT`](https://docs.pingcap.com/tidb/stable/sql-statement-savepoint) from `v6.2.0`, please notice the version of TiDB when you use this feature.

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
  fmt.Printf("insert ID: %d, Code: %s, Prict: %d\n",
    insertProduct.ID, insertProduct.Code, insertProduct.Price)

  readProduct := &Product{}
  db.First(&readProduct, "code = ?", "D42") // find product with code D42

  fmt.Printf("read ID: %d, Code: %s, Prict: %d\n",
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

## Connection Pool

GORM using [database/sql](https://pkg.go.dev/database/sql) to maintain connection pool

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

## Unsupported Databases

Some databases may be compatible with the `mysql` or `postgres` dialect, in which case you could just use the dialect for those databases.

For others, [you are encouraged to make a driver, pull request welcome!](write_driver.html)
