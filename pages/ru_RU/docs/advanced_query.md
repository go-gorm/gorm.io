---
title: Расширенный запрос
layout: страница
---

## Умный выбор полей

GORM позволяет выбирать определенные поля с помощью [`Select`](query.html), если вы часто используете их в своем приложении, вы можете использовать более короткий struct для выбора определенных полей автоматически

```go
type User struct {
  ID     uint
  Name   string
  Age    int
  Gender string
  // тысячи полей
}

type APIUser struct {
  ID   uint
  Name string
}

// Выбирает поля `id`, `name` автоматически при запросе
db.Model(&User{}).Limit(10).Find(&APIUser{})
// SELECT `id`, `name` FROM `users` LIMIT 10
```

## Блокировка (ДЛЯ ОБНОВЛЕНИЯ)

GORM поддерживает различные типы блокировок, например:

```go
DB.Clauses(clause.Locking{Strength: "UPDATE"}).Find(&users)
// SELECT * FROM `users` FOR UPDATE

DB.Clauses(clause.Locking{
  Strength: "SHARE",
  Table: clause.Table{Name: clause.CurrentTable},
}).Find(&users)
// SELECT * FROM `users` FOR SHARE OF `users`
```

Посмотрите [Чистый SQL и Конструктор SQL](sql_builder.html) для подробностей

## Под Запрос

Подзапрос может быть вложен в запрос, GORM сгенерирует подзапрос при использовании `*gorm.DB` объекта в качестве параметра

```go
db.Where("amount > ?", db.Table("orders").Select("AVG(amount)")).Find(&orders)
// SELECT * FROM "orders" WHERE amount > (SELECT AVG(amount) FROM "orders");

subQuery := db.Select("AVG(age)").Where("name LIKE ?", "name%").Table("users")
db.Select("AVG(age) as avgage").Group("name").Having("AVG(age) > (?)", subQuery).Find(&results)
// SELECT AVG(age) as avgage FROM `users` GROUP BY `name` HAVING AVG(age) > (SELECT AVG(age) FROM `users` WHERE name LIKE "name%")
```

### <span id="from_subquery">Из SubQuery (под запроса)</span>

GORM позволяет вам использовать подзапрос в FROM при помощи `Table`, например:

```go
db.Table("(?) as u", DB.Model(&User{}).Select("name", "age")).Where("age = ?", 18}).Find(&User{})
// SELECT * FROM (SELECT `name`,`age` FROM `users`) as u WHERE `age` = 18

subQuery1 := DB.Model(&User{}).Select("name")
subQuery2 := DB.Model(&Pet{}).Select("name")
db.Table("(?) as u, (?) as p", subQuery1, subQuery2).Find(&User{})
// SELECT * FROM (SELECT `name` FROM `users`) as u, (SELECT `name` FROM `pets`) as p
```

## <span id="group_conditions">Группировка условий</span>

Проще писать сложные SQL запросы с помощью группировки условий

```go
db.Where(
    DB.Where("pizza = ?", "pepperoni").Where(DB.Where("size = ?", "small").Or("size = ?", "medium")),
).Or(
    DB.Where("pizza = ?", "hawaiian").Where("size = ?", "xlarge"),
).Find(&Pizza{}).Statement

// SELECT * FROM `pizzas` WHERE (pizza = "pepperoni" AND (size = "small" OR size = "medium")) OR (pizza = "hawaiian" AND size = "xlarge")
```

## Именованные аргументы

GORM поддерживает именованные аргументы при помощи [`sql.NamedArg`](https://tip.golang.org/pkg/database/sql/#NamedArg) или `map[string]interface{}{}`, например:

```go
DB.Where("name1 = @name OR name2 = @name", sql.Named("name", "jinzhu")).Find(&user)
// SELECT * FROM `named_users` WHERE name1 = "jinzhu" OR name2 = "jinzhu"

DB.Where("name1 = @name OR name2 = @name", map[string]interface{}{"name": "jinzhu"}).First(&user)
// SELECT * FROM `named_users` WHERE name1 = "jinzhu" OR name2 = "jinzhu" ORDER BY `named_users`.`id` LIMIT 1
```

Смотрите [Чистый SQL и Конструктор SQL](sql_builder.html#named_argument) для подробностей

## Поиск в Map

GORM позволяет записывать результат запроса в `map[string]interface{}` или `[]map[string]interface{}`, не забудьте указать `Model` или `Table`, например:

```go
var result map[string]interface{}
DB.Model(&User{}).First(&result, "id = ?", 1)

var results []map[string]interface{}
DB.Table("users").Find(&results)
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

`Assign` назначение атрибутов в struct, независимо от того, найдена запись или нет, эти атрибуты не будут участвовать в генерации запроса SQL

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

Получить первую найденную запись, или создать новую с указанными параметрами (работает только с struct, map)

```go
// Пользователь не найден, создать новую запись с указанными параметрами
db.FirstOrCreate(&user, User{Name: "non_existing"})
// INSERT INTO "users" (name) VALUES ("non_existing");
// пользователь -> User{ID: 112, Name: "non_existing"}

// Найдена запись с параметрами `name` = `jinzhu`
db.Where(User{Name: "jinzhu"}).FirstOrCreate(&user)
// пользователь -> User{ID: 111, Name: "jinzhu", "Age}: 18
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

Подсказки оптимизатора позволяют просматривать план выполнения запроса.

```go
import "gorm.io/hints"

DB.Clauses(hints.New("MAX_EXECUTION_TIME(10000)")).Find(&User{})
// SELECT * /*+ MAX_EXECUTION_TIME(10000) */ FROM `users`
```

Индексные подсказки позволяют передавать индексированные подсказки к базе данных, если планировщик запросов запутается.

```go
import "gorm.io/hints"

DB.Clauses(hints.UseIndex("idx_user_name")).Find(&User{})
// SELECT * FROM `users` USE INDEX (`idx_user_name`)

DB.Clauses(hints.ForceIndex("idx_user_name", "idx_user_id").ForJoin()).Find(&User{})
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
  // ScanRows записывает строки в user
  db.ScanRows(rows, &user)

  // делаем что-то
}
```

## Найти в пакете(FindInBatches)

Запрашивать и обрабатывать записи в пакете

```go
// размер пакета 100
result := DB.Where("processed = ?", false).FindInBatches(&results, 100, func(tx *gorm.DB, batch int) error {
  for _, result := range results {
    // пакетная обработка найденных записей
  }

  tx.Save(&results)

  tx.RowsAffected // количество записей в текущем пакете

  batch // пакет 1, 2, 3

  // возвращение ошибки остановит обработку следующих пакетов 
  return nil
})

result.Error // возвращена ошибка
result.RowsAffected // количество обработанных записей во всех пакетах
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

Запросить один столбец из БД и записать в slice, если вы хотите получить несколько столбцов, используйте [`Scan`](#scan)

```go
var ages []int64
db.Find(&users).Pluck("age", &ages)

var names []string
db.Model(&User{}).Pluck("name", &names)

db.Table("deleted_users").Pluck("name", &names)

// Pluck с Distinct
DB.Model(&User{}).Distinct().Pluck("Name", &names)
// SELECT DISTINCT `name` FROM `users`

// Запрашивая более одной колонки, используйте `Scan` или `Find`, например:
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

## <span id="count">Количество</span>

Получить количество найденных записей

```go
var count int64
db.Model(&User{}).Where("name = ?", "jinzhu").Or("name = ?", "jinzhu 2").Count(&count)
// SELECT count(*) FROM users WHERE name = 'jinzhu' OR name = 'jinzhu 2'

db.Model(&User{}).Where("name = ?", "jinzhu").Count(&count)
// SELECT count(*) FROM users WHERE name = 'jinzhu'; (count)

db.Table("deleted_users").Count(&count)
// SELECT count(*) FROM deleted_users;

// Count with Distinct
DB.Model(&User{}).Distinct("name").Count(&count)
// SELECT COUNT(DISTINCT(`name`)) FROM `users`

db.Table("deleted_users").Select("count(distinct(name))").Count(&count)
// SELECT count(distinct(name)) FROM deleted_users

// Количество с использованием Group
users := []User{
  {Name: "name1"},
  {Name: "name2"},
  {Name: "name3"},
  {Name: "name3"},
}

DB.Model(&User{}).Group("name").Count(&count)
count // => 3
```
