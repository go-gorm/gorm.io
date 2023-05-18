---
title: Запрос
layout: страница
---

## Получение одного объекта

GORM предоставляет методы `First`, `Take`, `Last` для получения одного объекта из базы данных. Эти методы добавляют условие `LIMIT 1` при запросе к базе данных, но если запись не найдена, вернется ошибка `ErrRecordNotFound`.

```go
// Получение первой записи при сортировке по первичному ключу "id"
db.First(&user)
// SELECT * FROM users ORDER BY id LIMIT 1;

// Получение одной записи без указания порядка сортировки
db.Take(&user)
// SELECT * FROM users LIMIT 1;

// Получение последней записи, отсортированные по первичному ключу "id" по убыванию
db.Last(&user)
// SELECT * FROM users ORDER BY id DESC LIMIT 1;

result := db.First(&user)
result.RowsAffected // возвращает количество найденных записей
result.Error        // возвращает error или nil

// проверка ошибки на ErrRecordNotFound
errors.Is(result.Error, gorm.ErrRecordNotFound)
```

{% note warn %}
Если вы хотите избежать ошибки `ErrRecordNotFound`, используйте метод `Find`, например `db.Limit(1).Find(&user)`, метод `Find` принимает как структурные, так и срезанные данные
{% endnote %}

{% note warn %}
Использование `Find` без лимита для одного объекта `db.Find(&user)` запросит полную таблицу и вернет только первый объект, который не является исполнительным и недетерминированным
{% endnote %}

Методы `First` и `Last` найдут первую и последнюю запись (соответственно) в порядке, установленном первичным ключом. Они работают только тогда, когда указатель на целевую структуру передается методам в качестве аргумента или когда модель указана с помощью `db.Model()`. Кроме того, если для соответствующей модели не определен первичный ключ, то модель будет упорядочена по первому полю. Например:

```go
var user User
var users []User

// работает, потому что передается целевая структура
db.First(&user)
// SELECT * FROM `users` ORDER BY `users`.`id` LIMIT 1

// работает, потому что модель указана с помощью `db.Model()`
result := map[string]interface{}{}
db.Model(&User{}).First(&result)
// SELECT * FROM `users` ORDER BY `users`.`id` LIMIT 1

// не работает
result := map[string]interface{}{}
db.Table("users").First(&result)

// работает с методом `Take`
result := map[string]interface{}{}
db.Table("users").Take(&result)

// первичный ключ не определен, результаты будут упорядочены по первому полю (т.е. "Коду").
type Language struct {
  Code string
  Name string
}
db.First(&Language{})
// SELECT * FROM `languages` ORDER BY `languages`.`code` LIMIT 1
```

### Получение объектов по первичному ключу

Объекты могут быть извлечены с использованием первичного ключа с помощью [Встроенных условий](#inline_conditions), если первичным ключом является число. При работе со строками необходимо соблюдать особую осторожность, чтобы избежать SQL-инъекции; ознакомьтесь с [Раздел "Безопасность"](security.html) для получения подробной информации.

```go
db.First(&user, 10)
// SELECT * FROM users WHERE id = 10;

db.First(&user, "10")
// SELECT * FROM users WHERE id = 10;

db.Find(&users, []int{1,2,3})
// SELECT * FROM users WHERE id IN (1,2,3);
```

Если первичным ключом является строка (например, как uuid), запрос будет записан следующим образом:

```go
db.First(&user, "id = ?", "1b74413f-f3b8-409f-ac47-e8c062e3472a")
// SELECT * FROM users WHERE id = "1b74413f-f3b8-409f-ac47-e8c062e3472a";
```

Когда целевой объект имеет первичное значение, первичный ключ будет использоваться для построения условия, например:

```go
var user = User{ID: 10}
db.First(&user)
// SELECT * FROM users WHERE id = 10;

var result User
db.Model(User{ID: 10}).First(&result)
// SELECT * FROM users WHERE id = 10;
```

## Получение всех объектов

```go
// Получить все записи
result := db.Find(&users)
// SELECT * FROM users;

result.RowsAffected // возвращает количество найденных записей, равное `len(users)`
result.Error        // возвращает ошибку
```

## Условия

### Строковые условия

```go
// Получить первую совпадающую запись
db.Where("name = ?", "jinzhu").First(&user)
// SELECT * FROM users WHERE name = 'jinzhu' ORDER BY id LIMIT 1;

// Получить все совпадающие записи
db.Where("name <> ?", "jinzhu").Find(&users)
// SELECT * FROM users WHERE name <> 'jinzhu';

// IN
db.Where("name IN ?", []string{"jinzhu", "jinzhu 2"}).Find(&users)
// SELECT * FROM users WHERE name IN ('jinzhu','jinzhu 2');

// LIKE
db.Where("name LIKE ?", "%jin%").Find(&users)
// SELECT * FROM users WHERE name LIKE '%jin%';

// AND
db.Where("name = ? AND age >= ?", "jinzhu", "22").Find(&users)
// SELECT * FROM users WHERE name = 'jinzhu' AND age >= 22;

// Time
db.Where("updated_at > ?", lastWeek).Find(&users)
// SELECT * FROM users WHERE updated_at > '2000-01-01 00:00:00';

// BETWEEN
db.Where("created_at BETWEEN ? AND ?", lastWeek, today).Find(&users)
// SELECT * FROM users WHERE created_at BETWEEN '2000-01-01 00:00:00' AND '2000-01-08 00:00:00';
```

{% note warn %}
Если первичный ключ объекта был задан, то запрос условия не будет охватывать значение первичного ключа, а будет использовать его как условие "and". Например:
```go
var user = User{ID: 10}
db.Where("id = ?", 20).First(&user)
// SELECT * FROM users WHERE id = 10 and id = 20 ORDER BY id ASC LIMIT 1
```
Этот запрос выдал бы ошибку `record not found`. Поэтому установите атрибут первичного ключа, такой как `id`, равным нулю, прежде чем вы захотите использовать переменную, такую как `user`, для получения нового значения из базы данных.
{% endnote %}


### Условия в структурах и картах

```go
// Структура
db.Where(&User{Name: "jinzhu", Age: 20}).First(&user)
// SELECT * FROM users WHERE name = "jinzhu" AND age = 20 ORDER BY id LIMIT 1;

// Карта
db.Where(map[string]interface{}{"name": "jinzhu", "age": 20}).Find(&users)
// SELECT * FROM users WHERE name = "jinzhu" AND age = 20;

// Slice первичных ключей
db.Where([]int64{20, 21, 22}).Find(&users)
// SELECT * FROM users WHERE id IN (20, 21, 22);
```

{% note warn %}
**ПРИМЕЧАНИЕ** При запросе с помощью struct GORM будет выполнять запрос только с ненулевыми полями, это означает, что если значение вашего поля равно `0`, `"`, `false` или другие [нулевые значения](https://tour.golang.org/basics/12), это не будет использоваться для построения условий запроса, например:
{% endnote %}

```go
db.Where(&User{Name: "jinzhu", Age: 0}).Find(&users)
// SELECT * FROM users WHERE name = "jinzhu";
```

Чтобы включить нулевые значения в условия запроса, вы можете использовать карту, которая будет включать все ключевые значения в качестве условий запроса, например:

```go
db.Where(map[string]interface{}{"Name": "jinzhu", "Age": 0}).Find(&users)
// SELECT * FROM users WHERE name = "jinzhu" AND age = 0;
```

Для получения более подробной информации смотрите [Указание полей для поиска структуры](#specify_search_fields).

### <span id="specify_search_fields">Указание полей поиска для структуры</span>

При поиске с помощью структуры, вы можете указать конкретные значения из структуры для использования в запросе, передав в `Where()` соответствующее имя поля или таблицы, например:

```go
db.Where(&User{Name: "jinzhu"}, "name", "Age").Find(&users)
// SELECT * FROM users WHERE name = "jinzhu" AND age = 0;

db.Where(&User{Name: "jinzhu"}, "Age").Find(&users)
// SELECT * FROM users WHERE age = 0;
```

### <span id="inline_conditions">Встроенное условие</span>

Условия запроса могут быть встроены в такие методы, как `First` и `Find` аналогично `Where`.

```go
// Получить по первичному ключу, если бы это был нецелочисленный тип
db.First(&user, "id = ?", "string_primary_key")
// SELECT * FROM users WHERE id = 'string_primary_key';

// Обычный SQL
db.Find(&user, "name = ?", "jinzhu")
// SELECT * FROM users WHERE name = "jinzhu";

db.Find(&users, "name <> ? AND age > ?", "jinzhu", 20)
// SELECT * FROM users WHERE name <> "jinzhu" AND age > 20;

// Структура
db.Find(&users, User{Age: 20})
// SELECT * FROM users WHERE age = 20;

// Карта
db.Find(&users, map[string]interface{}{"age": 20})
// SELECT * FROM users WHERE age = 20;
```

### Условие Not

Build NOT conditions, works similar to `Where`

```go
db.Not("name = ?", "jinzhu").First(&user)
// SELECT * FROM users WHERE NOT name = "jinzhu" ORDER BY id LIMIT 1;

// Не в
db.Not(map[string]interface{}{"name": []string{"jinzhu", "jinzhu 2"}}).Find(&users)
// SELECT * FROM users WHERE name NOT IN ("jinzhu", "jinzhu 2");

// Структура
db.Not(User{Name: "jinzhu", Age: 18}).First(&user)
// SELECT * FROM users WHERE name <> "jinzhu" AND age <> 18 ORDER BY id LIMIT 1;

// Не в срезе первичных ключей
db.Not([]int64{1,2,3}).First(&user)
// SELECT * FROM users WHERE id NOT IN (1,2,3) ORDER BY id LIMIT 1;
```

### Условие Or

```go
db.Where("role = ?", "admin").Or("role = ?", "super_admin").Find(&users)
// SELECT * FROM users WHERE role = 'admin' OR role = 'super_admin';

// Структура
db.Where("name = 'jinzhu'").Or(User{Name: "jinzhu 2", Age: 18}).Find(&users)
// SELECT * FROM users WHERE name = 'jinzhu' OR (name = 'jinzhu 2' AND age = 18);

// Карта
db.Where("name = 'jinzhu'").Or(map[string]interface{}{"name": "jinzhu 2", "age": 18}).Find(&users)
// SELECT * FROM users WHERE name = 'jinzhu' OR (name = 'jinzhu 2' AND age = 18);
```

Для более сложных SQL-запросов. пожалуйста, обратитесь к [Групповые условия в расширенном запросе](advanced_query.html#group_conditions).

## Выбор определенных полей

`Select` позволяет вам указать поля, которые вы хотите извлечь из базы данных. В противном случае GORM выберет все поля по умолчанию.

```go
db.Select("name", "age").Find(&users)
// SELECT name, age FROM users;

db.Select([]string{"name", "age"}).Find(&users)
// SELECT name, age FROM users;

db.Table("users").Select("COALESCE(age,?)", 42).Rows()
// SELECT COALESCE(age,'42') FROM users;
```

Также ознакомьтесь с [Полями интеллектуального выбора](advanced_query.html#smart_select)

## Порядок сортировки Order

Указывает порядок при извлечении записей из базы данных

```go
db.Order("age desc, name").Find(&users)
// SELECT * FROM users ORDER BY age desc, name;

// Несколько сортировок
db.Order("age desc").Order("name").Find(&users)
// SELECT * FROM users ORDER BY age desc, name;

db.Clauses(clause.OrderBy{
  Expression: clause.Expr{SQL: "FIELD(id,?)", Vars: []interface{}{[]int{1, 2, 3}}, WithoutParentheses: true},
}).Find(&User{})
// SELECT * FROM users ORDER BY FIELD(id,1,2,3)
```

## Limit и Offset

`Limit` указывает максимальное количество извлекаемых записей. `Offset` указывает количество записей, которые необходимо пропустить, прежде чем начинать возвращать записи

```go
db.Limit(3).Find(&users)
// SELECT * FROM users LIMIT 3;

// Отмените условие ограничения с помощью -1
db.Limit(10).Find(&users1).Limit(-1).Find(&users2)
// SELECT * FROM users LIMIT 10; (users1)
// SELECT * FROM users; (users2)

db.Offset(3).Find(&users)
// SELECT * FROM users OFFSET 3;

db.Limit(10).Offset(5).Find(&users)
// SELECT * FROM users OFFSET 5 LIMIT 10;

// Отмените условие смещения с помощью -1
db.Offset(10).Find(&users1).Offset(-1).Find(&users2)
// SELECT * FROM users OFFSET 10; (users1)
// SELECT * FROM users; (users2)
```

Смотрите [Пагинация](scopes.html#разбивка на страницы) для получения подробной информации о том, как создать разбиение на страницы

## Group и Having

```go
type result struct {
  Date  time.Time
  Total int
}

db.Model(&User{}).Select("name, sum(age) as total").Where("name LIKE ?", "group%").Group("name").First(&result)
// SELECT name, sum(age) as total FROM `users` WHERE name LIKE "group%" GROUP BY `name` LIMIT 1


db.Model(&User{}).Select("name, sum(age) as total").Group("name").Having("name = ?", "group").Find(&result)
// SELECT name, sum(age) as total FROM `users` GROUP BY `name` HAVING name = "group"

rows, err := db.Table("orders").Select("date(created_at) as date, sum(amount) as total").Group("date(created_at)").Rows()
defer rows.Close()
for rows.Next() {
  ...
}

rows, err := db.Table("orders").Select("date(created_at) as date, sum(amount) as total").Group("date(created_at)").Having("sum(amount) > ?", 100).Rows()
defer rows.Close()
for rows.Next() {
  ...
}

type Result struct {
  Date  time.Time
  Total int64
}
db.Table("orders").Select("date(created_at) as date, sum(amount) as total").Group("date(created_at)").Having("sum(amount) > ?", 100).Scan(&results)
```

## Distinct

Выбор различных значений из модели

```go
db.Distinct("name", "age").Order("name, age desc").Find(&results)
```

`Distinct` работает с [`Pluck`](advanced_query.html#pluck) и [`Count`](advanced_query.html#count) тоже

## Joins

Указывает условия объединения

```go
type result struct {
  Name  string
  Email string
}

db.Model(&User{}).Select("users.name, emails.email").Joins("left join emails on emails.user_id = users.id").Scan(&result{})
// SELECT users.name, emails.email FROM `users` left join emails on emails.user_id = users.id

rows, err := db.Table("users").Select("users.name, emails.email").Joins("left join emails on emails.user_id = users.id").Rows()
for rows.Next() {
  ...
}

db.Table("users").Select("users.name, emails.email").Joins("left join emails on emails.user_id = users.id").Scan(&results)

// множественные соединения с параметром
db.Joins("JOIN emails ON emails.user_id = users.id AND emails.email = ?", "jinzhu@example.org").Joins("JOIN credit_cards ON credit_cards.user_id = users.id").Where("credit_cards.number = ?", "411111111111").Find(&user)
```

### Joins с предварительной загрузкой

Вы можете использовать `Joins` для быстрой загрузки ассоциаций с одним SQL, например:

```go
db.Joins("Company").Find(&users)
// SELECT `users`.`id`,`users`.`name`,`users`.`age`,`Company`.`id` AS `Company__id`,`Company`.`name` AS `Company__name` FROM `users` LEFT JOIN `companies` AS `Company` ON `users`.`company_id` = `Company`.`id`;

// inner join
db.InnerJoins("Company").Find(&users)
// SELECT `users`.`id`,`users`.`name`,`users`.`age`,`Company`.`id` AS `Company__id`,`Company`.`name` AS `Company__name` FROM `users` INNER JOIN `companies` AS `Company` ON `users`.`company_id` = `Company`.`id`;
```

Предзагрузка с условием

```go
db.Joins("Company", db.Where(&Company{Alive: true})).Find(&users)
// SELECT `users`.`id`,`users`.`name`,`users`.`age`,`Company`.`id` AS `Company__id`,`Company`.`name` AS `Company__name` FROM `users` LEFT JOIN `companies` AS `Company` ON `users`.`company_id` = `Company`.`id` AND `Company`.`alive` = true;
```

For more details, please refer to [Preloading (Eager Loading)](preload.html).

### Joins к производной таблице

Вы также можете использовать `Joins` для объединения производной таблицы.

```go
type User struct {
    Id  int
    Age int
}

type Order struct {
    UserId     int
    FinishedAt *time.Time
}

query := db.Table("order").Select("MAX(order.finished_at) as latest").Joins("left join user user on order.user_id = user.id").Where("user.age > ?", 18).Group("order.user_id")
db.Model(&Order{}).Joins("join (?) q on order.finished_at = q.latest", query).Scan(&results)
// SELECT `order`.`user_id`,`order`.`finished_at` FROM `order` join (SELECT MAX(order.finished_at) as latest FROM `order` left join user user on order.user_id = user.id WHERE user.age > 18 GROUP BY `order`.`user_id`) q on order.finished_at = q.latest
```


## <span id="scan">Scan</span>

Сканирование результатов в структуру работает аналогично тому, как мы используем `Find`

```go
type Result struct {
  Name string
  Age  int
}

var result Result
db.Table("users").Select("name", "age").Where("name = ?", "Antonio").Scan(&result)

// Raw SQL
db.Raw("SELECT name, age FROM users WHERE name = ?", "Antonio").Scan(&result)
```
