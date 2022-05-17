---
title: Производительность
layout: страница
---

GORM optimizes many things to improve the performance, the default performance should be good for most applications, but there are still some tips for how to improve it for your application.

## [Отключить транзакцию по умолчанию](transactions.html)

GORM performs write (create/update/delete) operations inside a transaction to ensure data consistency, which is bad for performance, you can disable it during initialization

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  SkipDefaultTransaction: true,
})
```

## [Подготовленный кеш](session.html)

Создает подготовленные данные при выполнении любого SQL и кэширует их для ускорения будущих вызовов

```go
// глобальный режим
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  PrepareStmt: true,
})

// Сессионный режим
tx := db.Session(&Session{PrepareStmt: true})
tx.First(&user, 1)
tx.Find(&users)
tx.Model(&user).Update("Age", 18)
```

{% note warn %}
**NOTE** Also refer how to enable interpolateparams for MySQL to reduce roundtrip https://github.com/go-sql-driver/mysql#interpolateparams
{% endnote %}

### [Конструктор SQL с подготовкой](sql_builder.html)

Prepared Statement works with RAW SQL also, for example:

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  PrepareStmt: true,
})

db.Raw("select sum(age) from users where role = ?", "admin").Scan(&age)
```

You can also use GORM API to prepare SQL with [DryRun Mode](session.html), and execute it with prepared statement later, checkout [Session Mode](session.html) for details

## Выбрать поля

By default GORM select all fields when querying, you can use `Select` to specify fields you want

```go
db.Select("Name", "Age").Find(&Users{})
```

Or define a smaller API struct to use the [smart select fields feature](advanced_query.html)

```go
type User struct {
  ID     uint
  Name   string
  Age    int
  Gender string
  // сотни полей
}

type APIUser struct {
  ID   uint
  Name string
}

// Выбрать `id`, `name` автоматически при запросе
db.Model(&User{}).Limit(10).Find(&APIUser{})
// SELECT `id`, `name` FROM `users` LIMIT 10
```

## [Итерация / Поиск в пакете](advanced_query.html)

Query and process records with iteration or in batches

## [Подсказки индексирования](hints.html)

[Index](indexes.html) is used to speed up data search and SQL query performance. `Index Hints` gives the optimizer information about how to choose indexes during query processing, which gives the flexibility to choose a more efficient execution plan than the optimizer

```go
import "gorm.io/hints"

db.Clauses(hints.UseIndex("idx_user_name")).Find(&User{})
// SELECT * FROM `users` USE INDEX (`idx_user_name`)

db.Clauses(hints.ForceIndex("idx_user_name", "idx_user_id").ForJoin()).Find(&User{})
// SELECT * FROM `users` FORCE INDEX FOR JOIN (`idx_user_name`,`idx_user_id`)"

db.Clauses(
    hints.ForceIndex("idx_user_name", "idx_user_id").ForOrderBy(),
    hints.IgnoreIndex("idx_user_name").ForGroupBy(),
).Find(&User{})
// SELECT * FROM `users` FORCE INDEX FOR ORDER BY (`idx_user_name`,`idx_user_id`) IGNORE INDEX FOR GROUP BY (`idx_user_name`)"
```

## Read/Write Splitting

Increase data throughput through read/write splitting, check out [Database Resolver](dbresolver.html)
