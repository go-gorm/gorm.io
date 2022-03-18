---
title: Bir Veritabanına Bağlanma
layout: sayfa
---

GORM resmi olarak MySQL, PostgreSQL, SQLite, SQL Server veritabanlarını destekler

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
**NOT:** `time.Time`'ı düzgün biçimde kullanabilmek için `parseTime` parametresini eklemelisiniz. ([daha fazla parametre](https://github.com/go-sql-driver/mysql#parameters)) UTF-8 kodunu tam olarak desteklemek için `charset=utf8`'i `charset=utf8mb4` olarak değiştirmelisiniz. Detaylı açıklamalar için [bu makaleye](https://mathiasbynens.be/notes/mysql-utf8mb4) bakın
{% endnote %}

MySQL Sürücüsü başlatma sırasında kullanılabilecek [bazı ileri konfigürasyonlar](https://github.com/go-gorm/mysql) sağlar. Örneğin:

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

### Sürücüyü Özelleştirme

GORM `DriverName` seçeneği ile MySQL sürücüsünü özelleştirmeye imkan tanır. Örneğin:

```go
import (
  _ "example.com/my_mysql_driver"
  "gorm.io/gorm"
)

db, err := gorm.Open(mysql.New(mysql.Config{
  DriverName: "my_mysql_driver",
  DSN: "gorm:gorm@tcp(localhost:9910)/gorm?charset=utf8&parseTime=True&loc=Local", // data source name, refer https://github.com/go-sql-driver/mysql#dsn-data-source-name
}), &gorm.Config{})
```

### Varolan veritabanı bağlantısı

GORM `*gorm.DB`'yi varolan bir veritabanı bağlantısı ile başlatmaya imkân tanır

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

Postgres veritabanı/sql sürücüsü olarak [pgx](https://github.com/jackc/pgx) kullanıyoruz. Bu varsayılan olarak hazırlanmış ifade önbelleğini aktif hale getiriyor. Kapatmak için:

```go
// https://github.com/go-gorm/postgres
db, err := gorm.Open(postgres.New(postgres.Config{
  DSN: "user=gorm password=gorm dbname=gorm port=9920 sslmode=disable TimeZone=Asia/Shanghai",
  PreferSimpleProtocol: true, // disables implicit prepared statement usage
}), &gorm.Config{})
```

### Sürücüyü Özelleştirme

GORM `DriverName` seçeneği ile PostgreSQL sürücüsünü özelleştirmeye imkan tanır. Örneğin:

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

### Varolan veritabanı bağlantısı

GORM `*gorm.DB`'yi varolan bir veritabanı bağlantısı ile başlatmaya imkân tanır

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
**NOTE:** Dosya yolu yerine ayrıca `file::memory:?cache=shared` kullanabilirsiniz. Bu, SQLite'a sistem hafızası içinde geçiçi bir veritabanı kullanmasını söyleyecektir. (Bunun için [SQLite dökümanlarına](https://www.sqlite.org/inmemorydb.html) bakın)
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

  // Otomatik Geçiş
  db.AutoMigrate(&User{})
  // Tablo seçeneklerini belirle
  db.Set("gorm:table_options", "ENGINE=Distributed(cluster, default, hits)").AutoMigrate(&User{})

  // Ekle
  db.Create(&user)

  // Seç
  db.Find(&user, "id = ?", 10)

  // Toplu Ekleme
  var users = []User{user1, user2, user3}
  db.Create(&users)
  // ...
}
```

## Bağlantı Havuzu

GORM bağlantı havuzunu sağlamak için [database/sql](https://pkg.go.dev/database/sql) kullanır

```go
sqlDB, err := db.DB()

// SetMaxIdleConns kullanılmayan bağlantı havuzundaki maksimum bağlantı sayısını belirler.
sqlDB.SetMaxIdleConns(10)

// SetMaxOpenConns sets the maximum number of open connections to the database.
sqlDB.SetMaxOpenConns(100)

// SetConnMaxLifetime sets the maximum amount of time a connection may be reused.
sqlDB.SetConnMaxLifetime(time.Hour)
```

Refer [Generic Interface](generic_interface.html) for details

## Desteklenmeyen Veritabanları

Bazı veritabanları `mysql` ya da `postgres` diyalekti ile uyumlu olabilir. Bu durumda söz konusu veritabanlarının diyalektini kullanabilirsiniz.

Diğerleri için, [bir sürücü üretip talep göndermenizi memnuniyetle karşılarız!](write_driver.html)
