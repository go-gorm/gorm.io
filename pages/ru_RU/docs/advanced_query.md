---
title: Расширенный запрос
layout: страница
---

## <span id="smart_select">Умный выбор полей</span>

GORM позволяет выбрать конкретные поля при помощи [`Select`](query.html), если вы часто используете объект в вашем приложении, возможно вы захотите определить меньший struct для использования с API, который может выбирать конкретные поля автоматически, например:

```go
type User struct {
  ID     uint
  Name   string
  Age    int
  Gender string
  // hundreds of fields
}

type APIUser struct {
  ID   uint
  Name string
}

// Выбор`id`, `name` автоматически при выборке
db.Model(&User{}).Limit(10).Find(&APIUser{})
// SELECT `id`, `name` FROM `users` LIMIT 10
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
```

Посмотрите [Чистый SQL и Конструктор SQL](sql_builder.html) для подробностей

## Под Запрос

Подзапрос может быть вложен в запрос, GORM сгенерирует подзапрос при использовании `*gorm.DB` объекта в качестве параметра

```go
db.Where("amount > (?)", db.Table("orders").Select("AVG(amount)")).Find(&orders)
// SELECT * FROM "orders" WHERE amount > (SELECT AVG(amount) FROM "orders");

subQuery := db.Select("AVG(age)").Where("name LIKE ?", "name%").Table("users")
db.Select("AVG(age) as avgage").Group("name").Having("AVG(age) > (?)", subQuery).Find(&results)
// SELECT AVG(age) as avgage FROM `users` GROUP BY `name` HAVING AVG(age) > (SELECT AVG(age) FROM `users` WHERE name LIKE "name%")
```

### <span id="from_subquery">Из SubQuery (под запроса)</span>

GORM позволяет вам использовать подзапрос в FROM при помощи метода `Table`, например:

```go
db.Table("(?) as u", db.Model(&User{}).Select("name", "age")).Where("age = ?", 18}).Find(&User{})
// SELECT * FROM (SELECT `name`,`age` FROM `users`) as u WHERE `age` = 18

subQuery1 := db.Model(&User{}).Select("name")
subQuery2 := db.Model(&Pet{}).Select("name")
db.Table("(?) as u, (?) as p", subQuery1, subQuery2).Find(&User{})
// SELECT * FROM (SELECT `name` FROM `users`) as u, (SELECT `name` FROM `pets`) as p
```

## <span id="group_conditions">Группировка условий</span>

Проще писать сложные SQL запросы с помощью группировки условий

```go
db.Where(
    db.Where("pizza = ?", "pepperoni").Where(db.Where("size = ?", "small").Or("size = ?", "medium")),
).Or(
    db.Where("pizza = ?", "hawaiian").Where("size = ?", "xlarge"),
).Find(&Pizza{}).Statement

// SELECT * FROM `pizzas` WHERE (pizza = "pepperoni" AND (size = "small" OR size = "medium")) OR (pizza = "hawaiian" AND size = "xlarge")
```

## Именованные аргументы

GORM поддерживает именованные аргументы при помощи [`sql.NamedArg`](https://tip.golang.org/pkg/database/sql/#NamedArg) или `map[string]interface{}{}`, например:

```go
db.Where("name1 = @name OR name2 = @name", sql.Named("name", "jinzhu")).Find(&user)
// SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu"

db.Where("name1 = @name OR name2 = @name", map[string]interface{}{"name": "jinzhu"}).First(&user)
// SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu" ORDER BY `users`.`id` LIMIT 1
```

Смотрите [Чистый SQL и Конструктор SQL](sql_builder.html#named_argument) для подробностей

## Поиск в Map

GORM allows scan result to `map[string]interface{}` or `[]map[string]interface{}`, don't forget to specify `Model` or `Table`, for example:

```go
var result map[string]interface{}
db.Model(&User{}).First(&result, "id = ?", 1)

var results []map[string]interface{}
db.Table("users").Find(&results)
```

## Первый или новый (FirstOrInit)

Получить первую найденную запись, или инициализировать новую с заданными параметрами (работает только с struct и map)

```go
// Пользователь не найден, инициализировать его с параметрами 
db.FirstOrInit(&user, User{Name: "non_existing"})
// пользователь -> User{Name: "non_existing"}

// Найти пользователя с параметром `name` = `jinzhu`
db.Where(User{Name: "jinzhu"}).FirstOrInit(&user)
// пользователь -> User{ID: 111, Name: "Jinzhu", Age: 18}

// Найденный пользователь с параметрами `name` = `jinzhu`
db.FirstOrInit(&user, map[string]interface{}{"name": "jinzhu"})
// пользователь -> User{ID: 111, Name: "Jinzhu", Age: 18}
```

инициализировать struct с дополнительными параметрами, если запись не найдена, эти `Attrs` не будут использованы в построении запроса SQL

```go
// Пользователь не найден, инициализировать struct с указанными параметрами и атрибутами
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// пользователь -> User{Name: "non_existing", Age: 20}

// Пользователь не найден, инициализировать struct с указанными параметрами и атрибутами
db.Where(User{Name: "non_existing"}).Attrs("age", 20).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// пользователь -> User{Name: "non_existing", Age: 20}

// Найден пользователь с параметрами `name` = `jinzhu`, атрибуты будут проигнорированы
db.Where(User{Name: "Jinzhu"}).Attrs(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = jinzhu' ORDER BY id LIMIT 1;
// пользователь -> User{ID: 111, Name: "Jinzhu", Age: 18}
```

`Assign` назначение атрибутов в struct, независимо от того, найдена запись или нет, эти атрибуты не будут участвовать в генерации запроса SQL и не будут сохранены в БД

```go
// Пользователь не найден, с указанными параметрами, инициализировать запись с указанными параметрами и назначенными assign атрибутами
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrInit(&user)
// пользователь -> User{Name: "non_existing", Age: 20}

// Пользователь найден с параметрами `name` = `jinzhu`, дополнить запись назначенными assign атрибутами
db.Where(User{Name: "Jinzhu"}).Assign(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = jinzhu' ORDER BY id LIMIT 1;
// пользователь -> User{ID: 111, Name: "Jinzhu", Age: 20}
```

## Первый или создать (FirstOrCreate)

Получить первую найденную запись или создать новую с указанными параметрами (работает только с struct, map)

```go
// Пользователь не найден, создать новую запись с заданными параметрами
db.FirstOrCreate(&user, User{Name: "non_existing"})
// INSERT INTO "users" (name) VALUES ("non_existing");
// user -> User{ID: 112, Name: "non_existing"}

// Найлен пользователь `name` = `jinzhu`
db.Where(User{Name: "jinzhu"}).FirstOrCreate(&user)
// user -> User{ID: 111, Name: "jinzhu", "Age": 18}
```

Создать struct с дополнительными атрибутами если запись не найдена, эти `Attrs` атрибуты не будут использованы в генерации SQL

```go
// Пользователь не найден, создать его с параметрами и атрибутами
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
// пользователь -> User{ID: 112, Name: "non_existing", Age: 20}

// Найден пользователь с параметрами `name` = `jinzhu`, атрибуты будут проигнорированы 
db.Where(User{Name: "jinzhu"}).Attrs(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'jinzhu' ORDER BY id LIMIT 1;
// пользователь -> User{ID: 111, Name: "jinzhu", Age: 18}
```

`Assign` назначение атрибутов к записи, будет работать независимо от того, найдена запись или нет.

```go
// Пользователь не найден, инициализировать новую запись с параметрами и назначить Assign атрибуты
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
// пользователь -> User{ID: 112, Name: "non_existing", Age: 20}

// Найден пользователь с параметрами `name` = `jinzhu`, обновим запись Assign атрибутами
db.Where(User{Name: "jinzhu"}).Assign(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'jinzhu' ORDER BY id LIMIT 1;
// UPDATE users SET age=20 WHERE id = 111;
// пользователь -> User{ID: 111, Name: "jinzhu", Age: 20}
```

## Оптимизатор/Индексирование подсказки

Подсказки оптимизатора позволяют контролировать оптимизатор запросов для выбора определенного плана выполнения запроса, GORM поддерживает его с помощью `gorm.io/hints`, например:

```go
import "gorm.io/hints"

db.Clauses(hints.New("MAX_EXECUTION_TIME(10000)")).Find(&User{})
// SELECT * /*+ MAX_EXECUTION_TIME(10000) */ FROM `users`
```

Индексные подсказки позволяют передавать индексированные подсказки к базе данных, если планировщик запросов запутается.

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
  // ScanRows это метод `gorm.DB`, может быть использован для сканирования записи в struct
  db.ScanRows(rows, &user)

  // что-то делаем
}
```

## Найти в пакете(FindInBatches)

Запрашивать и обрабатывать записи в пакете

```go
// batch size 100
result := db.Where("processed = ?", false).FindInBatches(&results, 100, func(tx *gorm.DB, batch int) error {
  for _, result := range results {
    // batch processing found records
  }

  tx.Save(&results)

  tx.RowsAffected // number of records in this batch

  batch // Batch 1, 2, 3

  // returns error will stop future batches
  return nil
})

result.Error // returned error
result.RowsAffected // processed records count in all batches
```

## Хуки запросов

GORM позволяет использовать хуки `AfterFind` для запроса, который будет вызыватся при выполнении запроса, посмотрите [Хуки](hooks.html) для подробностей

```go
func (u *User) AfterFind(tx *gorm.DB) (err error) {
  if u.Role == "" {
    u.Role = "user"
  }
  return
}
```

## <span id="pluck">Pluck</span>

Запросить один столбец из БД и записать в slice, если вы хотите получить несколько столбцов - используйте `Select` вместе с [`Scan`](query.html#scan) для этого

```go
var ages []int64
db.Model(&users).Pluck("age", &ages)

var names []string
db.Model(&User{}).Pluck("name", &names)

db.Table("deleted_users").Pluck("name", &names)

// Distinct Pluck
db.Model(&User{}).Distinct().Pluck("Name", &names)
// SELECT DISTINCT `name` FROM `users`

// Requesting more than one column, use `Scan` or `Find` like this:
db.Select("name", "age").Scan(&users)
db.Select("name", "age").Find(&users)
```

## Области

`Рамки` позволяют установить часто используемые запросы, которые можно использовать позже как методы

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
// Найти все заказы оплаченные кредитной картой и суммой более 1000

db.Scopes(AmountGreaterThan1000, PaidWithCod).Find(&orders)
// Найти все заказы с оплатой наложенным платежом и суммой более 1000

db.Scopes(AmountGreaterThan1000, OrderStatus([]string{"paid", "shipped"})).Find(&orders)
// Найти все оплаченные и отгруженные заказы с суммой более 1000
```

Checkout [Scopes](scopes.html) for details

## <span id="count">Количество</span>

Получить количество найденных записей

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
