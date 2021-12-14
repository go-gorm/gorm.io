---
title: Конструктор SQL
layout: страница
---

## Чистый SQL

Запрос сырых SQL с помощью `Scan`

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
db.Raw("SELECT SUM(age) FROM users WHERE role = ?", "admin").Scan(&age)

var users []User
db.Raw("UPDATE users SET name = ? WHERE age = ? RETURNING id, name", "jinzhu", 20).Scan(&users)
```

`Exec` с помощью сырого SQL

```go
db.Exec("DROP TABLE users")
db.Exec("UPDATE orders SET shipped_at = ? WHERE id IN ?", time.Now(), []int64{1, 2, 3})

// Exec с помощью сырого выражения SQL
db.Exec("UPDATE users SET money = ? WHERE name = ?", gorm.Expr("money * ? + ?", 10000, 1), "jinzhu")
```

{% note warn %}
**ПРИМЕЧАНИЕ** GORM позволяет кэшировать подготовленные операторы для повышения производительности, подробности смотрите в [Производительность](performance.html)
{% endnote %}

## <span id="named_argument">Именованные аргументы</span>

GORM поддерживает именованные аргументы с помощью [`sql.NamedArg`](https://tip.golang.org/pkg/database/sql/#NamedArg), `map[string]interface{}{}` или структуры, например:

```go
db.Where("name1 = @name OR name2 = @name", sql.Named("name", "jinzhu")).Find(&user)
// SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu"

db.Where("name1 = @name OR name2 = @name", map[string]interface{}{"name": "jinzhu2"}).First(&result3)
// SELECT * FROM `users` WHERE name1 = "jinzhu2" OR name2 = "jinzhu2" ORDER BY `users`.`id` LIMIT 1

// Именованные аргументы в сыром SQL
db.Raw("SELECT * FROM users WHERE name1 = @name OR name2 = @name2 OR name3 = @name",
   sql.Named("name", "jinzhu1"), sql.Named("name2", "jinzhu2")).Find(&user)
// SELECT * FROM users WHERE name1 = "jinzhu1" OR name2 = "jinzhu2" OR name3 = "jinzhu1"

db.Exec("UPDATE users SET name1 = @name, name2 = @name2, name3 = @name",
   sql.Named("name", "jinzhunew"), sql.Named("name2", "jinzhunew2"))
// UPDATE users SET name1 = "jinzhunew", name2 = "jinzhunew2", name3 = "jinzhunew"

db.Raw("SELECT * FROM users WHERE (name1 = @name AND name3 = @name) AND name2 = @name2",
   map[string]interface{}{"name": "jinzhu", "name2": "jinzhu2"}).Find(&user)
// SELECT * FROM users WHERE (name1 = "jinzhu" AND name3 = "jinzhu") AND name2 = "jinzhu2"

type NamedArgument struct {
    Name string
    Name2 string
}

db.Raw("SELECT * FROM users WHERE (name1 = @Name AND name3 = @Name) AND name2 = @Name2",
     NamedArgument{Name: "jinzhu", Name2: "jinzhu2"}).Find(&user)
// SELECT * FROM users WHERE (name1 = "jinzhu" AND name3 = "jinzhu") AND name2 = "jinzhu2"
```

## Режим DryRun

Генерировать `SQL` и его аргументы без выполнения, может быть использовано для подготовки или тестирования сгенерированного SQL. Смотрите [Сессии](session.html) для деталей

```go
stmt := db.Session(&Session{DryRun: true}).First(&user, 1).Statement
stmt.SQL.String() //=> SELECT * FROM `users` WHERE `id` = $1 ORDER BY `id`
stmt.Vars         //=> []interface{}{1}
```

## ToSQL

Возвращает сгенерированный `SQL` без выполнения.

GORM использует плейсхолдеры аргументов базы данных/sql для построения запроса SQL, которые автоматически защищают от инъекций SQL, но сгенерированный SQL не предоставляет гарантий безопасности. Пожалуйста, используйте его только для отладки.

```go
sql := DB.ToSQL(func(tx *gorm.DB) *gorm.DB {
  return tx.Model(&User{}).Where("id = ?", 100).Limit(10).Order("age desc").Find(&[]User{})
})
sql //=> SELECT * FROM "users" WHERE id = 100 AND "users"."deleted_at" IS NULL ORDER BY age desc LIMIT 10
```

## `Row` и `Rows`

Получение `*sql.Row` в результате запроса

```go
// Использование GORM API для построения SQL
row := db.Table("users").Where("name = ?", "jinzhu").Select("name", "age").Row()
row.Scan(&name, &age)

// Использование сырого SQL
row := db.Raw("select name, age, email from users where name = ?", "jinzhu").Row()
row.Scan(&name, &age, &email)
```

Получение `*sql.Rows` в результате запроса

```go
// Использование GORM API для построения SQL
rows, err := db.Model(&User{}).Where("name = ?", "jinzhu").Select("name, age, email").Rows()
defer rows.Close()
for rows.Next() {
  rows.Scan(&name, &age, &email)

  // делаем что-нибудь
}

// Сырой SQL
rows, err := db.Raw("select name, age, email from users where name = ?", "jinzhu").Rows()
defer rows.Close()
for rows.Next() {
  rows.Scan(&name, &age, &email)

  // делаем что-нибудь
}
```

Посмотрите [FindInBatches](advanced_query.html), как запрашивать и обрабатывать записи пакетом. Ознакомьтесь с [Группировка условий](advanced_query.html#group_conditions) для создания сложных SQL запросов

## Сканирование `*sql.Rows` в структуру

Используйте `ScanRows`, чтобы отсканировать строку в структуру, например:

```go
rows, err := db.Model(&User{}).Where("name = ?", "jinzhu").Select("name, age, email").Rows() // (*sql.Rows, error)
defer rows.Close()

var user User
for rows.Next() {
  // ScanRows сканирует строку в user
  db.ScanRows(rows, &user)

  // делаем что-нибудь
}
```

## Расширенный режим

### <span id="clauses">Clauses</span>

GORM использует SQL конструктор для генерирования SQL внутри себя. Для каждой операции GORM создает объект `*gorm.Statement`, все GORM API добавляют/изменяют `Оператор` для `Statement`, и в конце GORM генерирует SQL на основе этих операторов.

Например, при запросе с помощью `First` GORM добавляет следующие пункты в `Statement`

```go
clause.Select{Columns: "*"}
clause.From{Tables: clause.CurrentTable}
clause.Limit{Limit: 1}
clause.OrderByColumn{
  Column: clause.Column{Table: clause.CurrentTable, Name: clause.PrimaryKey},
}
```

Затем GORM строит окончательный запрос SQL в `Запросе` callback функции, например:

```go
Statement.Build("SELECT", "FROM", "WHERE", "GROUP BY", "ORDER BY", "LIMIT", "FOR")
```

Который сгенерирует SQL:

```sql
SELECT * FROM `users` ORDER BY `users`.`id` LIMIT 1
```

Вы можете определить свой `Оператор` и использовать его с GORM, но он должен реализовывать [Интерфейс](https://pkg.go.dev/gorm.io/gorm/clause?tab=doc#Interface)

Ознакомьтесь с [примерами](https://github.com/go-gorm/gorm/tree/master/clause) использования.

### Построитель операторов

Для различных баз данных Операторы могут генерировать разные SQL, например:

```go
db.Offset(10).Limit(5).Find(&users)
// Генерация для SQL Server
// SELECT * FROM "users" OFFSET 10 ROW FETCH NEXT 5 ROWS ONLY
// Генерация для MySQL
// SELECT * FROM `users` LIMIT 5 OFFSET 10
```

Что поддерживается, поскольку GORM позволяет драйверу базы данных регистрировать конструктор операторов для замены стандартного, возьмем в качестве примера [Limit](https://github.com/go-gorm/sqlserver/blob/512546241200023819d2e7f8f2f91d7fb3a52e42/sqlserver.go#L45)

### Варианты операторов

GORM определяет [много операторов](https://github.com/go-gorm/gorm/tree/master/clause), а некоторые операторы предоставляют расширенные опции и могут быть использованы для вашего приложения

Although most of them are rarely used, if you find GORM public API can't match your requirements, may be good to check them out, for example:

```go
db.Clauses(clause.Insert{Modifier: "IGNORE"}).Create(&user)
// INSERT IGNORE INTO users (name,age...) VALUES ("jinzhu",18...);
```

### StatementModifier

GORM предоставляет интерфейс [StatementModifier](https://pkg.go.dev/gorm.io/gorm?tab=doc#StatementModifier), позволяющий вам изменить выражение в соответствии с вашими требованиями, возьмем [Hints](hints.html) в качестве примера

```go
import "gorm.io/hints"

db.Clauses(hints.New("hint")).Find(&User{})
// SELECT * /*+ hint */ FROM `users`
```
