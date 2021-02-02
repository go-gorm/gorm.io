---
title: DBResolver
layout: page
---

DBResolver는 GROM에 다수의 database를 지원할 수 있도록 추가합니다. 아래 기능이 지원 가능 합니다.

* Multiple sources, replicas
* Read/Write Splitting
* Automatic connection switching based on the working table/struct
* Manual connection switching
* Sources/Replicas load balancing
* Works for RAW SQL

https://github.com/go-gorm/dbresolver

## Usage

```go
import (
  "gorm.io/gorm"
  "gorm.io/plugin/dbresolver"
  "gorm.io/driver/mysql"
)

db, err := gorm.Open(mysql.Open("db1_dsn"), &gorm.Config{})

db.Use(dbresolver.Register(dbresolver.Config{
  // use `db2` as sources, `db3`, `db4` as replicas
  Sources:  []gorm.Dialector{mysql.Open("db2_dsn")},
  Replicas: []gorm.Dialector{mysql.Open("db3_dsn"), mysql.Open("db4_dsn")},
  // sources/replicas load balancing policy
  Policy: dbresolver.RandomPolicy{},
}).Register(dbresolver.Config{
  // use `db1` as sources (DB's default connection), `db5` as replicas for `User`, `Address`
  Replicas: []gorm.Dialector{mysql.Open("db5_dsn")},
}, &User{}, &Address{}).Register(dbresolver.Config{
  // use `db6`, `db7` as sources, `db8` as replicas for `orders`, `Product`
  Sources:  []gorm.Dialector{mysql.Open("db6_dsn"), mysql.Open("db7_dsn")},
  Replicas: []gorm.Dialector{mysql.Open("db8_dsn")},
}, "orders", &Product{}, "secondary"))
```

## Transaction

Transaction을 사용할 때, DBResolver은 Source/Replica를 전환을 하지 않습니다.

## Automatic connection switching

DBResolver는 사용 중인 table/struct에 기반하여 연결을 자동 전환 합니다.

RAW SQL에서, DBResolver는 resolver를 매치시키기 위해 SQL에서 테이블 이름을 추출하고, 해당 `source`를 `SELECT`로 시작하지 않는(``SELECT... FOR UPDATE</0>를 제외하고) SQL이 올 때까지 사용합니다. 예를 들어:  </p>

<pre><code class="go">// `User` Resolver Examples
db.Table("users").Rows() // replicas `db5`
db.Model(&User{}).Find(&AdvancedUser{}) // replicas `db5`
db.Exec("update users set name = ?", "jinzhu") // sources `db1`
db.Raw("select name from users").Row().Scan(&name) // replicas `db5`
db.Create(&user) // sources `db1`
db.Delete(&User{}, "name = ?", "jinzhu") // sources `db1`
db.Table("users").Update("name", "jinzhu") // sources `db1`

// Global Resolver Examples
db.Find(&Pet{}) // replicas `db3`/`db4`
db.Save(&Pet{}) // sources `db2`

// Orders Resolver Examples
db.Find(&Order{}) // replicas `db8`
db.Table("orders").Find(&Report{}) // replicas `db8`
``</pre>

## Read/Write Splitting

[GORM callbacks](https://gorm.io/docs/write_plugins.html).에 기반한 DBResolver의 Read/Write 분리

`Query`, `Row` callback은, `Write` 모드가 지정되어 있지 않으면, `replicas`를 사용합니다. `Raw` callback의 statements는 조회로 간주되고, `SELECT`시작 하는 SQL문 일때 `replicas`를 사용합니다.

## Manual connection switching

```go
// Use Write Mode: read user from sources `db1`
db.Clauses(dbresolver.Write).First(&user)

// Specify Resolver: read user from `secondary`'s replicas: db8
db.Clauses(dbresolver.Use("secondary")).First(&user)

// Specify Resolver and Write Mode: read user from `secondary`'s sources: db6 or db7
db.Clauses(dbresolver.Use("secondary"), dbresolver.Write).First(&user)
```

## Load Balancing

GORM supports load balancing sources/replicas based on policy, the policy should be a struct implements following interface:

```go
type Policy interface {
    Resolve([]gorm.ConnPool) gorm.ConnPool
}
```

Currently only the `RandomPolicy` implemented and it is the default option if no other policy specified.

## Connection Pool

```go
db.Use(
  dbresolver.Register(dbresolver.Config{ /* xxx */ }).
  SetConnMaxIdleTime(time.Hour).
  SetConnMaxLifetime(24 * time.Hour).
  SetMaxIdleConns(100).
  SetMaxOpenConns(200)
)
```
