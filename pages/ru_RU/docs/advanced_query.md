---
title: Расширенный запрос
layout: страница
---

## <span id="smart_select">Умный выбор полей</span>

GORM позволяет выбрать конкретные поля при помощи [`Select`](query.html). Если вы часто используете это в вашем приложении, возможно вы захотите определить меньшую структуру для использования с API, который может выбирать конкретные поля автоматически, например:

```go
type User struct {
  ID     uint
  Name   string
  Age    int
  Gender string
  // следующие сотни полей
}

type APIUser struct {
  ID   uint
  Name string
}

// Выбор`id`, `name` автоматически при запросе
db.Model(&User{}).Limit(10).Find(&APIUser{})
// SELECT `id`, `name` FROM `users` LIMIT 10
```

{% note warn %}
**Примечание** Режим `QueryFields` будет выбираться по имени всех полей для текущей модели
{% endnote %}

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  QueryFields: true,
})

db.Find(&user)
// SELECT `users`.`name`, `users`.`age`, ... FROM `users` // with this option

// Режим сессии
db.Session(&gorm.Session{QueryFields: true}).Find(&user)
// SELECT `users`.`name`, `users`.`age`, ... FROM `users`
```

## Блокировка (ДЛЯ ОБНОВЛЕНИЯ)

GORM поддерживает различные типы блокировок, например:

```go
db.Clauses(clause.Locking{Strength: "UPDATE"}).Find(&users)
// SELECT * FROM `users` FOR UPDATE

db.Clauses(clause.Locking{
  Strength: "SHARE",
  Table: clause.Table{Name: clause.CurrentTable},
}).Find(&users)
// SELECT * FROM `users` FOR SHARE OF `users`

db.Clauses(clause.Locking{
  Strength: "UPDATE",
  Options: "NOWAIT",
}).Find(&users)
// SELECT * FROM `users` FOR UPDATE NOWAIT
```

Смотрите [Чистый SQL и Конструктор SQL](sql_builder.html) для получения более подробной информации

## Подзапрос

Подзапрос может быть вложен в запрос, GORM сгенерирует подзапрос при использовании `*gorm.DB` объекта в качестве параметра

```go
db.Where("amount > (?)", db.Table("orders").Select("AVG(amount)")).Find(&orders)
// SELECT * FROM "orders" WHERE amount > (SELECT AVG(amount) FROM "orders");

subQuery := db.Select("AVG(age)").Where("name LIKE ?", "name%").Table("users")
db.Select("AVG(age) as avgage").Group("name").Having("AVG(age) > (?)", subQuery).Find(&results)
// SELECT AVG(age) as avgage FROM `users` GROUP BY `name` HAVING AVG(age) > (SELECT AVG(age) FROM `users` WHERE name LIKE "name%")
```

### <span id="from_subquery">Из SubQuery (под запроса)</span>

GORM позволяет использовать подзапрос в FROM с методом `Table`, например:

```go
db.Table("(?) as u", db.Model(&User{}).Select("name", "age")).Where("age = ?", 18).Find(&User{})
// SELECT * FROM (SELECT `name`,`age` FROM `users`) as u WHERE `age` = 18

subQuery1 := db.Model(&User{}).Select("name")
subQuery2 := db.Model(&Pet{}).Select("name")
db.Table("(?) as u, (?) as p", subQuery1, subQuery2).Find(&User{})
// SELECT * FROM (SELECT `name` FROM `users`) as u, (SELECT `name` FROM `pets`) as p
```

## <span id="group_conditions">Группировка условий</span>

Легче написать сложный SQL-запрос с группировкой условий

```go
db.Where(
    db.Where("pizza = ?", "pepperoni").Where(db.Where("size = ?", "small").Or("size = ?", "medium")),
).Or(
    db.Where("pizza = ?", "hawaiian").Where("size = ?", "xlarge"),
).Find(&Pizza{}).Statement

// SELECT * FROM `pizzas` WHERE (pizza = "pepperoni" AND (size = "small" OR size = "medium")) OR (pizza = "hawaiian" AND size = "xlarge")
```

## IN с несколькими столбцами

Выборка IN с несколькими столбцами

```go
db.Where("(name, age, role) IN ?", [][]interface{}{{"jinzhu", 18, "admin"}, {"jinzhu2", 19, "user"}}).Find(&users)
// SELECT * FROM users WHERE (name, age, role) IN (("jinzhu", 18, "admin"), ("jinzhu 2", 19, "user"));
```

## Именованные аргументы

GORM поддерживает именованные аргументы при использовании [`sql.NamedArg`](https://tip.golang.org/pkg/database/sql/#NamedArg) или `map[string]interface{}{}`, например:

```go
db.Where("name1 = @name OR name2 = @name", sql.Named("name", "jinzhu")).Find(&user)
// SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu"

db.Where("name1 = @name OR name2 = @name", map[string]interface{}{"name": "jinzhu"}).First(&user)
// SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu" ORDER BY `users`.`id` LIMIT 1
```

Смотрите [Чистый SQL и Конструктор SQL](sql_builder.html#named_argument) для подробностей

## Find с картами

GORM позволяет отображать результаты сканирования в `map[string]interface{}` или `[]map[string]interface{}`, не забудьте указать `Model` или `Table`, как в примере ниже:

```go
result := map[string]interface{}{}
db.Model(&User{}).First(&result, "id = ?", 1)

var results []map[string]interface{}
db.Table("users").Find(&results)
```

## FirstOrInit

Получить первую найденную запись, или инициализировать новую с заданными параметрами (работает только со структурой и картой)

```go
// Пользователь user не найден, создаем новую запись с данными значениями
db.FirstOrInit(&user, User{Name: "non_existing"})
// user -> User{Name: "non_existing"}

// Найден user с `name` = `jinzhu`
db.Where(User{Name: "jinzhu"}).FirstOrInit(&user)
// user -> User{ID: 111, Name: "Jinzhu", Age: 18}

// Найден user с `name` = `jinzhu`
db.FirstOrInit(&user, map[string]interface{}{"name": "jinzhu"})
// user -> User{ID: 111, Name: "Jinzhu", Age: 18}
```

инициализировать структуру с дополнительными параметрами. Если запись не найдена, эти `Attrs` не будут использованы в построении запроса SQL

```go
// Пользователь не найден, инициализировать структуру с указанными параметрами и атрибутами Attrs
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// user -> User{Name: "non_existing", Age: 20}

// Пользователь не найден, инициализировать структуру с указанными параметрами и атрибутами Attrs
db.Where(User{Name: "non_existing"}).Attrs("age", 20).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// user -> User{Name: "non_existing", Age: 20}

// Найден пользователь с параметрами `name` = `jinzhu`, атрибуты Attrs будут проигнорированы
db.Where(User{Name: "Jinzhu"}).Attrs(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = jinzhu' ORDER BY id LIMIT 1;
// пользователь -> User{ID: 111, Name: "Jinzhu", Age: 18}
```

Метод `Assign` назначает атрибуты в структуру, независимо от того, найдена запись или нет, эти атрибуты не будут участвовать в генерации запроса SQL и не будут сохранены в БД

```go
// User не найден, создать его с данными условиями и с атрибутами в Assign 
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrInit(&user)
// user -> User{Name: "non_existing", Age: 20}

// Найден user с `name` = `jinzhu`, обновить запись с атрибутами в Assign 
db.Where(User{Name: "Jinzhu"}).Assign(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "Jinzhu", Age: 20}
```

## FirstOrCreate

Получить первую совпавшую запись или создать новую с указанными параметрами (работает только со структурами и картами)

```go
// User не найден, создать новую запись с заданными условиями
db.FirstOrCreate(&user, User{Name: "non_existing"})
// INSERT INTO "users" (name) VALUES ("non_existing");
// user -> User{ID: 112, Name: "non_existing"}

// Найден user с `name` = `jinzhu`
db.Where(User{Name: "jinzhu"}).FirstOrCreate(&user)
// user -> User{ID: 111, Name: "jinzhu", "Age": 18}
```

Создание структуры с дополнительными атрибутами если запись не найдена. Эти `Attrs` атрибуты не будут использованы в построении SQL запроса

```go
// User не найден, создать его с данными условиями и атрибутами в Attrs
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
// user -> User{ID: 112, Name: "non_existing", Age: 20}

// Найден user с `name` = `jinzhu`, атрибуты в Attrs будут проигнорированы
db.Where(User{Name: "jinzhu"}).Attrs(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "jinzhu", Age: 18}
```

Метод `Assign` назначает атрибуты к записи, будет работать независимо от того, найдена запись или нет.

```go
// User не найден, создать его с данными условиями и атрибутами в Assign
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
// user -> User{ID: 112, Name: "non_existing", Age: 20}

// Найден user с `name` = `jinzhu`, обновить эту запись с атрибутами в Assign
db.Where(User{Name: "jinzhu"}).Assign(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'jinzhu' ORDER BY id LIMIT 1;
// UPDATE users SET age=20 WHERE id = 111;
// user -> User{ID: 111, Name: "jinzhu", Age: 20}
```

## Оптимизатор/Индексы

Подсказки оптимизатора позволяют контролировать оптимизатор запросов для выбора определенного плана выполнения запроса, GORM поддерживает его с помощью `gorm.io/hints`, например:

```go
import "gorm.io/hints"

db.Clauses(hints.New("MAX_EXECUTION_TIME(10000)")).Find(&User{})
// SELECT * /*+ MAX_EXECUTION_TIME(10000) */ FROM `users`
```

Индексные подсказки позволяют передавать индексированные подсказки к базе данных, если планировщик запросов ошибается.

```go
import "gorm.io/hints"

db.Clauses(hints.UseIndex("idx_user_name")).Find(&User{})
// SELECT * FROM `users` USE INDEX (`idx_user_name`)

db.Clauses(hints.ForceIndex("idx_user_name", "idx_user_id").ForJoin()).Find(&User{})
// SELECT * FROM `users` FORCE INDEX FOR JOIN (`idx_user_name`,`idx_user_id`)"
```

Смотрите [Подсказки оптимизатор/Индекс/Комментарий](hints.html) для получения более подробной информации

## Итерация

GORM поддерживает итерацию по строкам

```go
rows, err := db.Model(&User{}).Where("name = ?", "jinzhu").Rows()
defer rows.Close()

for rows.Next() {
  var user User
  // ScanRows метод `gorm.DB`, он может быть использован для сканирования строки в struct
  db.ScanRows(rows, &user)

  // делаем что-то 
}
```

## FindInBatches

Запрашивать и обрабатывать записи в пакете

```go
// размер пакета 100
result := db.Where("processed = ?", false).FindInBatches(&results, 100, func(tx *gorm.DB, batch int) error {
  for _, result := range results {
    // пакетная обработка найденных записей
  }

  tx.Save(&results)

  tx.RowsAffected // количество записей в этом пакете

  batch // Batch 1, 2, 3

  // возврат ошибки остановит обработку
  return nil
})

result.Error // возвращаемая ошибка
result.RowsAffected // кол-во обработанных записей во всех пакетах
```

## Хуки запросов

GORM позволяет использовать хуки `AfterFind` для запроса, который будет вызываться при выполнении запроса. Смотрите [Хуки](hooks.html) для подробностей

```go
func (u *User) AfterFind(tx *gorm.DB) (err error) {
  if u.Role == "" {
    u.Role = "user"
  }
  return
}
```

## <span id="pluck">Pluck</span>

Запрос одного столбца из базы данных и запись его в слайс, если вы хотите получить несколько столбцов - используйте `Select` вместе с [`Scan`](query.html#scan) для этого

```go
var ages []int64
db.Model(&users).Pluck("age", &ages)

var names []string
db.Model(&User{}).Pluck("name", &names)

db.Table("deleted_users").Pluck("name", &names)

// Distinct Pluck
db.Model(&User{}).Distinct().Pluck("Name", &names)
// SELECT DISTINCT `name` FROM `users`

// Запрос больше одного столбца, используйте `Scan` или `Find` как в примере:
db.Select("name", "age").Scan(&users)
db.Select("name", "age").Find(&users)
```

## Scopes

`Scopes` позволяют указать часто используемые запросы, которые можно использовать позже как методы

```go
func AmountGreaterThan1000(db *gorm.DB) *gorm.DB {
  return db.Where("amount > ?", 1000)
}

func PaidWithCreditCard(db *gorm.DB) *gorm.DB {
  return db.Where("pay_mode_sign = ?", "C")
}

func PaidWithCod(db *gorm.DB) *gorm.DB {
  return db.Where("pay_mode_sign = ?", "C")
}

func OrderStatus(status []string) func (db *gorm.DB) *gorm.DB {
  return func (db *gorm.DB) *gorm.DB {
    return db.Where("status IN (?)", status)
  }
}

db.Scopes(AmountGreaterThan1000, PaidWithCreditCard).Find(&orders)
// Найдите все заказы по кредитным картам на сумму более 1000

db.Scopes(AmountGreaterThan1000, PaidWithCod).Find(&orders)
// Найдите все заказы наложенным платежом на сумму более 1000

db.Scopes(AmountGreaterThan1000, OrderStatus([]string{"paid", "shipped"})).Find(&orders)
// Найдите все оплаченные, отправленные заказы на сумму более 1000
```

Смотрите [Scopes](scopes.html) для получения дополнительной информации

## <span id="count">Count</span>

Получение количество найденных записей

```go
var count int64
db.Model(&User{}).Where("name = ?", "jinzhu").Or("name = ?", "jinzhu 2").Count(&count)
// SELECT count(1) FROM users WHERE name = 'jinzhu' OR name = 'jinzhu 2'

db.Model(&User{}).Where("name = ?", "jinzhu").Count(&count)
// SELECT count(1) FROM users WHERE name = 'jinzhu'; (count)

db.Table("deleted_users").Count(&count)
// SELECT count(1) FROM deleted_users;

// Count with Distinct
db.Model(&User{}).Distinct("name").Count(&count)
// SELECT COUNT(DISTINCT(`name`)) FROM `users`

db.Table("deleted_users").Select("count(distinct(name))").Count(&count)
// SELECT count(distinct(name)) FROM deleted_users

// Count with Group
users := []User{
  {Name: "name1"},
  {Name: "name2"},
  {Name: "name3"},
  {Name: "name3"},
}

db.Model(&User{}).Group("name").Count(&count)
count // => 3
```
