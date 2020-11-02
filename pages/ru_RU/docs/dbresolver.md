---
title: DBResolver
layout: страница
---

DBResolver добавляет поддержку нескольких баз данных для GORM, поддерживаются следующие функции:

* Несколько источников, реплики
* Разделение чтения/записи
* Автоматическое переключение подключения на основе таблицы/struct
* Ручное переключение подключения
* Исходные/репликационные балансировки нагрузки
* Работает для RAW SQL

https://github.com/go-gorm/dbresolver

## Использование

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

## Транзакция

При использовании транзакции DBResolver будет использовать транзакцию и не будет переключаться на реплики

## Автоматическое переключение подключения

DBResolver автоматически переключит соединение на основе таблицы/struct

Для RAW SQL, DBResolver извлечет имя таблицы из SQL в соответствии с резолвером, и будет использовать `sources`, если SQL не начинается с `SELECT` (исключая SELECT... FOR UPDATE</code>), например:

```go
// `User` Resolver Examples
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
```

## Разделение чтения/записи

Разделение Чтения/Записи с DBResolver на основе текущего [Обратного вызова GORM](https://gorm.io/docs/write_plugins.html).

Для `Query`, `Row` обратного вызова, будет использовать `реплики`, если только указан режим `Write` Для `Raw` обратного вызова, считается только чтением и будут использоваться `реплики`, если SQL начинается с `SELECT`

## Ручное переключение подключения

```go
// Use Write Mode: read user from sources `db1`
db.Clauses(dbresolver.Write).First(&user)

// Specify Resolver: read user from `secondary`'s replicas: db8
db.Clauses(dbresolver.Use("secondary")).First(&user)

// Specify Resolver and Write Mode: read user from `secondary`'s sources: db6 or db7
db.Clauses(dbresolver.Use("secondary"), dbresolver.Write).First(&user)
```

## Балансировка Нагрузки

GORM поддерживает балансировку нагрузки мастер/реплики на основе политики, политика - это struct реализующий следующий интерфейс:

```go
type Policy interface {
    Resolve([]gorm.ConnPool) gorm.ConnPool
}
```

В настоящее время реализована только `RandomPolicy` и это вариант по умолчанию, если не указана политика.

## Пул подключений

```go
db.Use(
  dbresolver.Register(dbresolver.Config{ /* xxx */ }).
  SetConnMaxIdleTime(time.Hour).
  SetConnMaxLifetime(24 * time.Hour).
  SetMaxIdleConns(100).
  SetMaxOpenConns(200)
)
```
