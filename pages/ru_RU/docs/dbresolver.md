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

DB, err := gorm.Open(mysql.Open("db1_dsn"), &gorm.Config{})

DB.Use(dbresolver.Register(dbresolver.Config{
  // используется `db2` как основная, `db3`, `db4` как реплика
  Sources:  []gorm.Dialector{mysql.Open("db2_dsn")},
  Replicas: []gorm.Dialector{mysql.Open("db3_dsn"), mysql.Open("db4_dsn")},
  // основные/реплика политика балансировки нагрузки
  Policy: dbresolver.RandomPolicy{},
}).Register(dbresolver.Config{
  // используется `db1` как основная (подключение по умолчанию для DB), `db5` как реплика  для `User`, `Address`
  Replicas: []gorm.Dialector{mysql.Open("db5_dsn")},
}, &User{}, &Address{}).Register(dbresolver.Config{
  // используется `db6`, `db7` как основная , `db8` как реплика для `orders`, `Product`
  Sources:  []gorm.Dialector{mysql.Open("db6_dsn"), mysql.Open("db7_dsn")},
  Replicas: []gorm.Dialector{mysql.Open("db8_dsn")},
}, "orders", &Product{}, "secondary"))
```

## Транзакция

При использовании транзакции DBResolver будет использовать транзакцию и не будет переключаться на реплики

## Автоматическое переключение подключения

DBResolver автоматически переключит соединение на основе таблицы/struct

For RAW SQL, DBResolver will extract the table name from the SQL to match the resolver, and will use `sources` unless the SQL begins with `SELECT` (excepts `SELECT... FOR UPDATE`), for example:

```go
// Пример `User` Resolver
DB.Table("users").Rows() // replicas `db5`
DB.Model(&User{}).Find(&AdvancedUser{}) // replicas `db5`
DB.Exec("update users set name = ?", "jinzhu") // sources `db1`
DB.Raw("select name from users").Row().Scan(&name) // replicas `db5`
DB.Create(&user) // sources `db1`
DB.Delete(&User{}, "name = ?", "jinzhu") // sources `db1`
DB.Table("users").Update("name", "jinzhu") // sources `db1`

// Пример глобального Resolver
DB.Find(&Pet{}) // replicas `db3`/`db4`
DB.Save(&Pet{}) // sources `db2`

// Пример Resolver для Orders
DB.Find(&Order{}) // replicas `db8`
DB.Table("orders").Find(&Report{}) // replicas `db8`
```

## Разделение чтения/записи

Read/Write splitting with DBResolver based on the current used [GORM callbacks](https://gorm.io/docs/write_plugins.html).

Для `Query`, `Row` обратного вызова, будет использовать `реплики`, если только указан режим `Write` Для `Raw` обратного вызова, считается только чтением и будут использоваться `реплики`, если SQL начинается с `SELECT`

## Ручное переключение подключения

```go
// Использовать режим Write: чтение данных пользователя из источника `db1`
DB.Clauses(dbresolver.Write).First(&user)

// Установить Resolver: чтение данных пользователя из реплики: db8
DB.Clauses(dbresolver.Use("secondary")).First(&user)

// Установить Resolver и режим Write: чтение данных пользователя из реплики: db6 или db7
DB.Clauses(dbresolver.Use("secondary"), dbresolver.Write).First(&user)
```

## Балансировка Нагрузки

GORM supports load balancing sources/replicas based on policy, the policy should be a struct implements following interface:

```go
type Policy interface {
    Resolve([]gorm.ConnPool) gorm.ConnPool
}
```

Currently only the `RandomPolicy` implemented and it is the default option if no other policy specified.

## Пул подключений

```go
DB.Use(
  dbresolver.Register(dbresolver.Config{ /* xxx */ }).
  SetConnMaxIdleTime(time.Hour).
  SetConnMaxLifetime(24 * time.Hour).
  SetMaxIdleConns(100).
  SetMaxOpenConns(200)
)
```
