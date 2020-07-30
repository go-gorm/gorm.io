---
title: Производительность
layout: страница
---

GORM оптимизирует многое для улучшения производительности, производительность по умолчанию должна быть хорошая для большинства приложений, но есть несколько советов по улучшению вашего приложения.

## [Отключить транзакцию по умолчанию](transactions.html)

GORM выполняет операции записи (создания/обновления/удаления) внутри транзакции для обеспечения согласованности данных, что плохо для производительности, вы можете отключить её во время инициализации

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

### [Конструктор SQL с подготовкой](sql_builder.html)

Подготовленное заявление работает также с RAW SQL, например:

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  PrepareStmt: true,
})

db.Raw("select sum(age) from users where role = ?", "admin").Scan(&age)
```

Вы также можете использовать GORM API для подготовки SQL с [DryRun Mode](session.html), и выполните его с подготовленным выражением позже, смотрите [режим сессии](session.html) для получения подробной информации

## Выбрать поля

По умолчанию GORM выбирает все поля при запросе, вы можете использовать `Select` для указания полей

```go
db.Select("Name", "Age").Find(&Users{})
```

Или определите меньший struct API для использования функции [умных полей](advanced_query.html)

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

Запрашивать и обрабатывать записи с итерациями или партиями

## [Подсказки индексирования](hints.html)

[Индекс](indexes.html) используется для ускорения поиска данных и производительности SQL-запроса. `Подсказки индексирования` дают оптимизатору информацию о том, как выбрать индексы во время обработки запроса, что дает гибкость выбора более эффективного плана выполнения, чем оптимизатор

```go
import "gorm.io/hints"

DB.Clauses(hints.UseIndex("idx_user_name")).Find(&User{})
// SELECT * FROM `users` USE INDEX (`idx_user_name`)

DB.Clauses(hints.ForceIndex("idx_user_name", "idx_user_id").ForJoin()).Find(&User{})
// SELECT * FROM `users` FORCE INDEX FOR JOIN (`idx_user_name`,`idx_user_id`)"

DB.Clauses(
    hints.ForceIndex("idx_user_name", "idx_user_id").ForOrderBy(),
    hints.IgnoreIndex("idx_user_name").ForGroupBy(),
).Find(&User{})
// SELECT * FROM `users` FORCE INDEX FOR ORDER BY (`idx_user_name`,`idx_user_id`) IGNORE INDEX FOR GROUP BY (`idx_user_name`)"
```
