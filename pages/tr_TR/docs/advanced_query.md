---
title: Gelişmiş Sorgu
layout: page
---

## <span id="smart_select">Akıllı Alan Seçimi</span>

GORM [`Select`](query.html) ile belirli alanları seçmenize izin verir. Eğer bunu sıklıkla kullanıyorsanız isterseniz daha küçük bir struct tanımı ile apiniz için kullanabilirsiniz.Örnek olarak:

```go
type User struct {
  ID     uint
  Name   string
  Age    int
  Gender string
  // bir sürü alan olabilir
}

type APIUser struct {
  ID   uint
  Name string
}

// `id` ve `name` alanları otomatik olarak sorgunuza eklenir
db.Model(&User{}).Limit(10).Find(&APIUser{})
// SELECT `id`, `name` FROM `users` LIMIT 10
```

{% note warn %}
**NOT** `Sorgu alanları` otomatik olarak belirttiğiniz modele eklenir
{% endnote %}

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  QueryFields: true,
})

db.Find(&user)
// SELECT `users`.`name`, `users`.`age`, ... FROM `users` // with this option

// Session Modu
db.Session(&gorm.Session{QueryFields: true}).Find(&user)
// SELECT `users`.`name`, `users`.`age`, ... FROM `users`
```

## Kilitleme (Kaydın güncellenmesi için)

GORM bir kaç farklı türde kilitlemeyi destekler. örneğin:

```go
db.Clauses(clause.Locking{Strength: "UPDATE"}).Find(&users)
// SELECT * FROM `users` FOR UPDATE

db.Clauses(clause.Locking{
  Strength: "SHARE",
  Table: clause.Table{Name: clause.CurrentTable},
}).Find(&users)
// SELECT * FROM `users` FOR SHARE OF `users`
```

[Raw SQL and SQL Builder](sql_builder.html) daha fazla detay için referans

## SubQuery

A subquery can be nested within a query, GORM can generate subquery when using a `*gorm.DB` object as param

```go
db.Where("amount > (?)", db.Table("orders").Select("AVG(amount)")).Find(&orders)
// SELECT * FROM "orders" WHERE amount > (SELECT AVG(amount) FROM "orders");

subQuery := db.Select("AVG(age)").Where("name LIKE ?", "name%").Table("users")
db.Select("AVG(age) as avgage").Group("name").Having("AVG(age) > (?)", subQuery).Find(&results)
// SELECT AVG(age) as avgage FROM `users` GROUP BY `name` HAVING AVG(age) > (SELECT AVG(age) FROM `users` WHERE name LIKE "name%")
```

### <span id="from_subquery">From SubQuery</span>

GORM allows you using subquery in FROM clause with method `Table`, for example:

```go
db.Table("(?) as u", db.Model(&User{}).Select("name", "age")).Where("age = ?", 18}).Find(&User{})
// SELECT * FROM (SELECT `name`,`age` FROM `users`) as u WHERE `age` = 18

subQuery1 := db.Model(&User{}).Select("name")
subQuery2 := db.Model(&Pet{}).Select("name")
db.Table("(?) as u, (?) as p", subQuery1, subQuery2).Find(&User{})
// SELECT * FROM (SELECT `name` FROM `users`) as u, (SELECT `name` FROM `pets`) as p
```

## <span id="group_conditions">Group Conditions</span>

Easier to write complicated SQL query with Group Conditions

```go
db.Where(
    db.Where("pizza = ?", "pepperoni").Where(db.Where("size = ?", "small").Or("size = ?", "medium")),
).Or(
    db.Where("pizza = ?", "hawaiian").Where("size = ?", "xlarge"),
).Find(&Pizza{}).Statement

// SELECT * FROM `pizzas` WHERE (pizza = "pepperoni" AND (size = "small" OR size = "medium")) OR (pizza = "hawaiian" AND size = "xlarge")
```

## Named Argument

GORM supports named arguments with [`sql.NamedArg`](https://tip.golang.org/pkg/database/sql/#NamedArg) or `map[string]interface{}{}`, for example:

```go
db.Where("name1 = @name OR name2 = @name", sql.Named("name", "jinzhu")).Find(&user)
// SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu"

db.Where("name1 = @name OR name2 = @name", map[string]interface{}{"name": "jinzhu"}).First(&user)
// SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu" ORDER BY `users`.`id` LIMIT 1
```

Check out [Raw SQL and SQL Builder](sql_builder.html#named_argument) for more detail

## Find To Map

GORM allows scan result to `map[string]interface{}` or `[]map[string]interface{}`, don't forget to specify `Model` or `Table`, for example:

```go
var result map[string]interface{}
db.Model(&User{}).First(&result, "id = ?", 1)

var results []map[string]interface{}
db.Table("users").Find(&results)
```

## FirstOrInit

Get first matched record or initialize a new instance with given conditions (only works with struct or map conditions)

```go
// User not found, initialize it with give conditions
db.FirstOrInit(&user, User{Name: "non_existing"})
// user -> User{Name: "non_existing"}

// Found user with `name` = `jinzhu`
db.Where(User{Name: "jinzhu"}).FirstOrInit(&user)
// user -> User{ID: 111, Name: "Jinzhu", Age: 18}

// Found user with `name` = `jinzhu`
db.FirstOrInit(&user, map[string]interface{}{"name": "jinzhu"})
// user -> User{ID: 111, Name: "Jinzhu", Age: 18}
```

initialize struct with more attributes if record not found, those `Attrs` won't be used to build SQL query

```go
// User not found, initialize it with give conditions and Attrs
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// user -> User{Name: "non_existing", Age: 20}

// User not found, initialize it with give conditions and Attrs
db.Where(User{Name: "non_existing"}).Attrs("age", 20).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// user -> User{Name: "non_existing", Age: 20}

// Found user with `name` = `jinzhu`, attributes will be ignored
db.Where(User{Name: "Jinzhu"}).Attrs(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "Jinzhu", Age: 18}
```

`Assign` attributes to struct regardless it is found or not, those attributes won't be used to build SQL query and the final data won't be saved into database

```go
// User not found, initialize it with give conditions and Assign attributes
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrInit(&user)
// user -> User{Name: "non_existing", Age: 20}

// Found user with `name` = `jinzhu`, update it with Assign attributes
db.Where(User{Name: "Jinzhu"}).Assign(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "Jinzhu", Age: 20}
```

## FirstOrCreate

Get first matched record or create a new one with given conditions (only works with struct, map conditions)

```go
// User not found, create a new record with give conditions
db.FirstOrCreate(&user, User{Name: "non_existing"})
// INSERT INTO "users" (name) VALUES ("non_existing");
// user -> User{ID: 112, Name: "non_existing"}

// Found user with `name` = `jinzhu`
db.Where(User{Name: "jinzhu"}).FirstOrCreate(&user)
// user -> User{ID: 111, Name: "jinzhu", "Age": 18}
```

Create struct with more attributes if record not found, those `Attrs` won't be used to build SQL query

```go
// User not found, create it with give conditions and Attrs
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
// user -> User{ID: 112, Name: "non_existing", Age: 20}

// Found user with `name` = `jinzhu`, attributes will be ignored
db.Where(User{Name: "jinzhu"}).Attrs(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "jinzhu", Age: 18}
```

`Assign` attributes to the record regardless it is found or not and save them back to the database.

```go
// User not found, initialize it with give conditions and Assign attributes
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
// user -> User{ID: 112, Name: "non_existing", Age: 20}

// Found user with `name` = `jinzhu`, update it with Assign attributes
db.Where(User{Name: "jinzhu"}).Assign(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'jinzhu' ORDER BY id LIMIT 1;
// UPDATE users SET age=20 WHERE id = 111;
// user -> User{ID: 111, Name: "jinzhu", Age: 20}
```

## Optimizer/Index Hints

Optimizer hints allow to control the query optimizer to choose a certain query execution plan, GORM supports it with `gorm.io/hints`, e.g:

```go
import "gorm.io/hints"

db.Clauses(hints.New("MAX_EXECUTION_TIME(10000)")).Find(&User{})
// SELECT * /*+ MAX_EXECUTION_TIME(10000) */ FROM `users`
```

Index hints allow passing index hints to the database in case the query planner gets confused.

```go
import "gorm.io/hints"

db.Clauses(hints.UseIndex("idx_user_name")).Find(&User{})
// SELECT * FROM `users` USE INDEX (`idx_user_name`)

db.Clauses(hints.ForceIndex("idx_user_name", "idx_user_id").ForJoin()).Find(&User{})
// SELECT * FROM `users` FORCE INDEX FOR JOIN (`idx_user_name`,`idx_user_id`)"
```

Refer [Optimizer Hints/Index/Comment](hints.html) for more details

## Iteration

GORM supports iterating through Rows

```go
rows, err := db.Model(&User{}).Where("name = ?", "jinzhu").Rows()
defer rows.Close()

for rows.Next() {
  var user User
  // ScanRows is a method of `gorm.DB`, it can be used to scan a row into a struct
  db.ScanRows(rows, &user)

  // do something
}
```

## FindInBatches

Query and process records in batch

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

## Query Hooks

GORM allows hooks `AfterFind` for a query, it will be called when querying a record, refer [Hooks](hooks.html) for details

```go
func (u *User) AfterFind(tx *gorm.DB) (err error) {
  if u.Role == "" {
    u.Role = "user"
  }
  return
}
```

## <span id="pluck">Pluck</span>

Query single column from database and scan into a slice, if you want to query multiple columns, use `Select` with [`Scan`](query.html#scan) instead

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

## Scopes

`Scopes` allows you to specify commonly-used queries which can be referenced as method calls

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
// Find all credit card orders and amount greater than 1000

db.Scopes(AmountGreaterThan1000, PaidWithCod).Find(&orders)
// Find all COD orders and amount greater than 1000

db.Scopes(AmountGreaterThan1000, OrderStatus([]string{"paid", "shipped"})).Find(&orders)
// Find all paid, shipped orders that amount greater than 1000
```

Checkout [Scopes](scopes.html) for details

## <span id="count">Count</span>

Get matched records count

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
