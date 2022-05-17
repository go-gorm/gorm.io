---
title: Производительность
layout: страница
---

В GORM используется много оптимизаций для улучшения производительности и производительность по умолчанию должна быть достаточной для большинства приложений, но все же есть несколько советов, как улучшить ее для вашего приложения.

## [Отключить транзакцию по умолчанию](transactions.html)

GORM выполняет операции записи (создание/обновление/удаление) внутри транзакции для обеспечения согласованности данных, что плохо сказывается на производительности, но вы можете отключить это поведение во время инициализации

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
**NOTE** Также смотрите https://github.com/go-sql-driver/mysql#interpolateparams, как включить параметр interpolateparams для MySQL, чтобы сократить количество запросов
{% endnote %}

### [Конструктор SQL с подготовкой](sql_builder.html)

Подготовленный запрос работает также с сырым SQL, например:

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  PrepareStmt: true,
})

db.Raw("select sum(age) from users where role = ?", "admin").Scan(&age)
```

Вы также можете использовать GORM API для подготовки SQL с [DryRun Mode](session.html), и выполнить его с подготовленным запросом позже, смотрите [режим сессии](session.html) для получения подробной информации

## Выбрать поля

По умолчанию GORM выбирает все поля при запросе, вы можете использовать `Select` для указания нужных вам полей

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
