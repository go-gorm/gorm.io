---
title: Конструктор SQL
layout: страница
---

## Чистый SQL

Запрос сырого SQL

```go
type Result struct {
  ID   int
  Name string
  Age  int
}

var result Result
db.Raw("SELECT id, name, age FROM users WHERE name = ?", 3).Scan(&result)

db.Raw("SELECT id, name, age FROM users WHERE name = ?", 3).Scan(&result)

var age int
DB.Raw("select sum(age) from users where role = ?", "admin").Scan(&age)
```

Выполнение сырого SQL

```go
db.Exec("DROP TABLE users")
db.Exec("UPDATE orders SET shipped_at=? WHERE id IN ?", time.Now(), []int64{1,2,3})

// SQL Выражение
DB.Exec("update users set money=? where name = ?", gorm.Expr("money * ? + ?", 10000, 1), "jinzhu")
```

**ПРИМЕЧАНИЕ** GORM позволяет кэшировать подготовленное утверждение для повышения производительности, смотрите [Производительность](performance.html) для подробностей

## `Строка` & `Строки`

Получить результат в `*sql.Row`

```go
// Использовать GORM API построитель SQL
row := db.Table("users").Where("name = ?", "jinzhu").Select("name", "age").Row()
row.Scan(&name, &age)

// Использовать сырой SQL
row := db.Raw("select name, age, email from users where name = ?", "jinzhu").Row()
row.Scan(&name, &age, &email)
```

Получить результат как `*sql.Rows`

```go
// Использовать GORM API построитель SQL
rows, err := db.Model(&User{}).Where("name = ?", "jinzhu").Select("name, age, email").Rows()
defer rows.Close()
for rows.Next() {
  rows.Scan(&name, &age, &email)

  // что-то делаем
}

// Сырой SQL
rows, err := db.Raw("select name, age, email from users where name = ?", "jinzhu").Rows()
defer rows.Close()
for rows.Next() {
  rows.Scan(&name, &age, &email)

  // что-то делаем
}
```

Смотрите [FindInBatches](advanced_query.html), для подробностей как запрашивать и обрабатывать записи в пакете Ознакомьтесь с [Групповые Условия](advanced_query.html#group_conditions) для создания сложных SQL запросов

## <span id="named_argument">Именованные аргументы</span>

GORM поддерживает именованные аргументы при помощи [`sql.NamedArg`](https://tip.golang.org/pkg/database/sql/#NamedArg) или `map[string]interface{}{}`, например:

```go
DB.Where("name1 = @name OR name2 = @name", sql.Named("name", "jinzhu")).Find(&user)
// SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu"

DB.Where("name1 = @name OR name2 = @name", map[string]interface{}{"name": "jinzhu2"}).First(&result3)
// SELECT * FROM `users` WHERE name1 = "jinzhu2" OR name2 = "jinzhu2" ORDER BY `users`.`id` LIMIT 1

DB.Raw("SELECT * FROM users WHERE name1 = @name OR name2 = @name2 OR name3 = @name", sql.Named("name", "jinzhu1"), sql.Named("name2", "jinzhu2")).Find(&user)
// SELECT * FROM users WHERE name1 = "jinzhu1" OR name2 = "jinzhu2" OR name3 = "jinzhu1"

DB.Exec("UPDATE users SET name1 = @name, name2 = @name2, name3 = @name", sql.Named("name", "jinzhunew"), sql.Named("name2", "jinzhunew2"))
// UPDATE users SET name1 = "jinzhunew", name2 = "jinzhunew2", name3 = "jinzhunew"

DB.Raw("SELECT * FROM users WHERE (name1 = @name AND name3 = @name) AND name2 = @name2", map[string]interface{}{"name": "jinzhu", "name2": "jinzhu2"}).Find(&user)
// SELECT * FROM users WHERE (name1 = "jinzhu" AND name3 = "jinzhu") AND name2 = "jinzhu2"
```

## Сканировать `*sql.Rows` в struct

```go
rows, err := db.Model(&User{}).Where("name = ?", "jinzhu").Select("name, age, email").Rows() // (*sql.Rows, error)
defer rows.Close()

for rows.Next() {
  var user User
  // ScanRows сканирует строку в user
  db.ScanRows(rows, &user)

  // что-то делаем
}
```

## Режим DryRun

Генерировать `SQL` без выполнения, может быть использован для подготовки или тестирования сгенерированного SQL, смотрите [Session](session.html) для подробностей

```go
stmt := DB.Session(&Session{DryRun: true}).First(&user, 1).Statement
stmt.SQL.String() //=> SELECT * FROM `users` WHERE `id` = $1 ORDER BY `id`
stmt.Vars         //=> []interface{}{1}
```

## Дополнительно

### Оговорки

GORM использует SQL конструктор при генерации SQL для каждой операции, GORM создает объект `*gorm.Statement`, применяет все GORM API добавлять/изменять `Clause (Оговорки)` для `Statement`, и в конце генерирует GORM SQL на основе этих выражений

Например, при запросе с помощью `First` он добавляет следующие оговорки в `Statement`

```go
clause.Select{Columns: "*"}
clause.From{Tables: clause.CurrentTable}
clause.Limit{Limit: 1}
clause.OrderByColumn{
  Column: clause.Column{Table: clause.CurrentTable, Name: clause.PrimaryKey},
}
```

Затем GORM наконец-то выполняет запрос SQL в callback функции, например:

```go
Statement.Build("SELECT", "FROM", "WHERE", "GROUP BY", "ORDER BY", "LIMIT", "FOR")
```

Который генерирует SQL:

```sql
SELECT * FROM `users` ORDER BY `users`.`id` LIMIT 1
```

Вы можете определить `Clause` и использовать его с GORM, он должен реализовывать [Interface](https://pkg.go.dev/gorm.io/gorm/clause?tab=doc#Interface)

Ознакомьтесь с [примерами](https://github.com/go-gorm/gorm/tree/master/clause)

### Построитель оговорок

Для различных баз данных Оговорки могут генерировать разные SQL, например:

```go
db.Offset(10).Limit(5).Find(&users)
// Сгенерировано для SQL Server
// SELECT * FROM "users" OFFSET 10 ROW FETCH NEXT 5 ROWS ONLY
// Сгенерировано для MySQL
// SELECT * FROM `users` LIMIT 5 OFFSET 10
```

Что поддерживается, потому что GORM позволяет зарегистрировать драйвер базы данных Clause Builder, чтобы заменить стандартный, например, [Limit](https://github.com/go-gorm/sqlserver/blob/512546241200023819d2e7f8f2f91d7fb3a52e42/sqlserver.go#L45)

### Варианты оговорок

GORM определяет [Многие оговорки](https://github.com/go-gorm/gorm/tree/master/clause), а некоторые оговорки предоставляют расширенные опции и могут быть использованы для вашего приложения

Хотя большинство из них редко используется, если вы обнаружили, что публичный GORM API не соответствует вашим требованиям, может быть полезно проверить их, например:

```go
DB.Clauses(clause.Insert{Modifier: "IGNORE"}).Create(&user)
// INSERT IGNORE INTO users (name,age...) VALUES ("jinzhu",18...);
```

### StatementModifier

GORM предоставляет интерфейс [StatementModifier](https://pkg.go.dev/gorm.io/gorm?tab=doc#StatementModifier), который позволяет вам изменить statement в соответствии с вашими требованиями, смотрите [Hints](hints.html) в качестве примера

```go
import "gorm.io/hints"

DB.Clauses(hints.New("hint")).Find(&User{})
// SELECT * /*+ hint */ FROM `users`
```
