---
title: 高级查询
layout: page
---

## 智能选择字段

GORM 允许通过 [`Select`](query.html) 方法选择特定的字段，如果您在应用程序中经常使用此功能，你可以定义一个较小的 API 结构体，以实现自动选择特定的字段。

```go
type User struct {
  ID     uint
  Name   string
  Age    int
  Gender string
  // 假设后面还有几百个字段...
}

type APIUser struct {
  ID   uint
  Name string
}

// 查询时会自动选择 `id`, `name` 字段
db.Model(&User{}).Limit(10).Find(&APIUser{})
// SELECT `id`, `name` FROM `users` LIMIT 10
```

## Locking (FOR UPDATE)

GORM 支持多种类型的锁，例如：

```go
DB.Clauses(clause.Locking{Strength: "UPDATE"}).Find(&users)
// SELECT * FROM `users` FOR UPDATE

DB.Clauses(clause.Locking{
  Strength: "SHARE",
  Table: clause.Table{Name: clause.CurrentTable},
}).Find(&users)
// SELECT * FROM `users` FOR SHARE OF `users`
```

参考 [原生 SQL 及构造器](sql_builder.html) 获取详情

## 子查询

子查询可以嵌套在查询中，GORM 允许在使用 `*gorm.DB` 对象作为参数时生成子查询

```go
db.Where("amount > ?", db.Table("orders").Select("AVG(amount)")).Find(&orders)
// SELECT * FROM "orders" WHERE amount > (SELECT AVG(amount) FROM "orders");

subQuery := db.Select("AVG(age)").Where("name LIKE ?", "name%").Table("users")
db.Select("AVG(age) as avgage").Group("name").Having("AVG(age) > (?)", subQuery).Find(&results)
// SELECT AVG(age) as avgage FROM `users` GROUP BY `name` HAVING AVG(age) > (SELECT AVG(age) FROM `users` WHERE name LIKE "name%")
```

## <span id="group_conditions">Group 条件</span>

使用 Group 条件可以更轻松的编写复杂 SQL 查询

```go
db.Where(
    DB.Where("pizza = ?", "pepperoni").Where(DB.Where("size = ?", "small").Or("size = ?", "medium")),
).Or(
    DB.Where("pizza = ?", "hawaiian").Where("size = ?", "xlarge"),
).Find(&Pizza{}).Statement

// SELECT * FROM `pizzas` WHERE (pizza = "pepperoni" AND (size = "small" OR size = "medium")) OR (pizza = "hawaiian" AND size = "xlarge")
```

## 命名参数

GORM 支持 [`sql.NamedArg`](https://tip.golang.org/pkg/database/sql/#NamedArg) 和 `map[string]interface{}{}` 形式的命名参数，例如：

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

type Result struct { Name string Age  int } var result Result db.Table("users").Select("name", "age").Where("name = ?", "Antonio").Scan(&result) // Raw SQL db.Raw("SELECT name, age FROM users WHERE name = ?", "Antonio").Scan(&result)

## Find 至 map

GORM 允许扫描结果至 `map[string]interface{}` 或 `[]map[string]interface{}`，此时别忘了指定 `Model` 或 `Table`，例如：

```go
var result map[string]interface{}
DB.Model(&User{}).First(&result, "id = ?", 1)

var results []map[string]interface{}
DB.Table("users").Find(&results)
```

## FirstOrInit

获取第一个匹配的记录，或者根据给定的条件初始化一个新的记录（仅支持 sturct 和 map 条件）

```go
// 未找到 user，则根据给定的条件初始化一条记录
db.FirstOrInit(&user, User{Name: "non_existing"})
// user -> User{Name: "non_existing"}

// 找到了 `name` = `jinzhu` 的 user
db.Where(User{Name: "jinzhu"}).FirstOrInit(&user)
// user -> User{ID: 111, Name: "Jinzhu", Age: 18}

// 找到了 `name` = `jinzhu` 的 user
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

`Assign` attributes to struct regardless it is found or not, those attributes won't be used to build SQL query

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

Get first matched record, or create a new one with given conditions (only works with struct, map conditions)

```go
// User not found, create a new record with give conditions
db.FirstOrCreate(&user, User{Name: "non_existing"})
// INSERT INTO "users" (name) VALUES ("non_existing");
// user -> User{ID: 112, Name: "non_existing"}

// Found user with `name` = `jinzhu`
db.Where(User{Name: "jinzhu"}).FirstOrCreate(&user)
// user -> User{ID: 111, Name: "jinzhu", "Age}: 18
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

`Assign` attributes to the record regardless it is found or not, and save them back to the database.

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

Optimizer hints allow us to control the query optimizer to choose a certain query execution plan.

```go
import "gorm.io/hints"

DB.Clauses(hints.New("MAX_EXECUTION_TIME(10000)")).Find(&User{})
// SELECT * /*+ MAX_EXECUTION_TIME(10000) */ FROM `users`
```

Index hints allow passing index hints to the database in case the query planner gets confused.

```go
import "gorm.io/hints"

DB.Clauses(hints.UseIndex("idx_user_name")).Find(&User{})
// SELECT * FROM `users` USE INDEX (`idx_user_name`)

DB.Clauses(hints.ForceIndex("idx_user_name", "idx_user_id").ForJoin()).Find(&User{})
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
  // ScanRows scan a row into user
  db.ScanRows(rows, &user)

  // do something
}
```

## FindInBatches

Query and process records in batch

```go
// batch size 100
result := DB.Where("processed = ?", false).FindInBatches(&results, 100, func(tx *gorm.DB, batch int) error {
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

Query single column from database and scan into a slice, if you want to query multiple columns, use [`Scan`](#scan) instead

```go
var ages []int64
db.Find(&users).Pluck("age", &ages)

var names []string
db.Model(&User{}).Pluck("name", &names)

db.Table("deleted_users").Pluck("name", &names)

// Distinct Pluck
DB.Model(&User{}).Distinct().Pluck("Name", &names)
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
    return db.Scopes(AmountGreaterThan1000).Where("status IN (?)", status)
  }
}

db.Scopes(AmountGreaterThan1000, PaidWithCreditCard).Find(&orders)
// Find all credit card orders and amount greater than 1000

db.Scopes(AmountGreaterThan1000, PaidWithCod).Find(&orders)
// Find all COD orders and amount greater than 1000

db.Scopes(AmountGreaterThan1000, OrderStatus([]string{"paid", "shipped"})).Find(&orders)
// Find all paid, shipped orders that amount greater than 1000
```

## <span id="count">Count</span>

Get matched records count

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

// Count with Group
users := []User{
  {Name: "name1"},
  {Name: "name2"},
  {Name: "name3"},
  {Name: "name3"},
}

DB.Model(&User{}).Group("name").Count(&count)
count // => 3
```
