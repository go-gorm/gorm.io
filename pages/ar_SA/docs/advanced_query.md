---
title: Advanced Query
layout: page
---

## Smart Select Fields

GORM allows select specific fields with [`Select`](query.html), if you often use this in your application, maybe you want to define a smaller API struct that select specific fields automatically

```go
type Result struct {
  Name string
  Age  int
}

var result Result
db. Table("users"). Select("name", "age"). Where("name = ?", "Antonio"). Scan(&result)

// Raw SQL
db. Raw("SELECT name, age FROM users WHERE name = ?", "Antonio").
```

## Locking (FOR UPDATE)

GORM supports different types of locks, for example:

```go
Table("deleted_users"). Pluck("name", &names)

// Distinct Pluck
DB. Distinct(). Pluck("Name", &names)
// SELECT DISTINCT `name` FROM `users`

// Requesting more than one column, use `Scan` or `Find` like this:
db. Scan(&users)
db. Find(&users)
```

Refer [Raw SQL and SQL Builder](sql_builder.html) for more detail

## SubQuery

A subquery can be nested within a query, GORM can generate subquery when using a `*gorm.DB` object as param

```go
Count(&count)
// SELECT COUNT(DISTINCT(`name`)) FROM `users`

db. Select("count(distinct(name))").
```

## <span id="group_conditions">Group Conditions</span>

Easier to write complicated SQL query with Group Conditions

```go
db. Where(
    DB. Where("pizza = ?", "pepperoni"). Where(DB. Where("size = ?", "small"). Or("size = ?", "medium")),
). Or(
    DB. Where("pizza = ?", "hawaiian"). Where("size = ?", "xlarge"),
). Find(&Pizza{}). Statement

// SELECT * FROM `pizzas` WHERE (pizza = "pepperoni" AND (size = "small" OR size = "medium")) OR (pizza = "hawaiian" AND size = "xlarge")
```

## Named Argument

GORM supports named arguments with [`sql.NamedArg`](https://tip.golang.org/pkg/database/sql/#NamedArg) or `map[string]interface{}{}`, for example:

```go
Or("name = ?", "jinzhu 2"). Count(&count)
// SELECT count(*) FROM users WHERE name = 'jinzhu' OR name = 'jinzhu 2'

db.
```

Check out [Raw SQL and SQL Builder](sql_builder.html#named_argument) for more detail

## Find To Map

GORM allows scan result to `map[string]interface{}` or `[]map[string]interface{}`, don't forgot to specify `Model` or `Table`, for example:

```go
var result map[string]interface{}
DB. Model(&User{}). First(&result, "id = ?", 1)

var results []map[string]interface{}
DB. Table("users"). Find(&results)
```

## FirstOrInit

Get first matched record, or initialize a new one with given conditions (only works with struct, map conditions)

```go
import "gorm.io/hints"

DB. UseIndex("idx_user_name")). Find(&User{})
// SELECT * FROM `users` USE INDEX (`idx_user_name`)

DB. ForceIndex("idx_user_name", "idx_user_id"). ForJoin()). Find(&User{})
// SELECT * FROM `users` FORCE INDEX FOR JOIN (`idx_user_name`,`idx_user_id`)"
```

initialize struct with more attributes if record not found, those `Attrs` won't be used to build SQL query

```go
Or("name = ?", "jinzhu 2"). Count(&count)
// SELECT count(*) FROM users WHERE name = 'jinzhu' OR name = 'jinzhu 2'

db. Count(&count)
// SELECT count(*) FROM users WHERE name = 'jinzhu'; (count)

db. Count(&count)
// SELECT count(*) FROM deleted_users;

// Count with Distinct
DB. Distinct("name"). Count(&count)
// SELECT COUNT(DISTINCT(`name`)) FROM `users`

db. Select("count(distinct(name))"). Count(&count)
// SELECT count(distinct(name)) FROM deleted_users

// Count with Group
users := []User{
  {Name: "name1"},
  {Name: "name2"},
  {Name: "name3"},
  {Name: "name3"},
}

DB.
```

`Assign` attributes to struct regardless it is found or not, those attributes won't be used to build SQL query

```go
Find(&users). Pluck("age", &ages)

var names []string
db. Pluck("name", &names)

db. Table("deleted_users"). Pluck("name", &names)

// Distinct Pluck
DB. Distinct(). Pluck("Name", &names)
// SELECT DISTINCT `name` FROM `users`

// Requesting more than one column, use `Scan` or `Find` like this:
db. Scan(&users)
db. Find(&users)
```

## FirstOrCreate

Get first matched record, or create a new one with given conditions (only works with struct, map conditions)

```go
Or("name = ?", "jinzhu 2"). Count(&count)
// SELECT count(*) FROM users WHERE name = 'jinzhu' OR name = 'jinzhu 2'

db. Count(&count)
// SELECT count(*) FROM users WHERE name = 'jinzhu'; (count)

db.
```

Create struct with more attributes if record not found, those `Attrs` won't be used to build SQL query

```go
Or("name = ?", "jinzhu 2"). Count(&count)
// SELECT count(*) FROM users WHERE name = 'jinzhu' OR name = 'jinzhu 2'

db. Count(&count)
// SELECT count(*) FROM users WHERE name = 'jinzhu'; (count)

db. Count(&count)
// SELECT count(*) FROM deleted_users;

// Count with Distinct
DB. Distinct("name"). Count(&count)
// SELECT COUNT(DISTINCT(`name`)) FROM `users`

db. Select("count(distinct(name))"). Count(&count)
// SELECT count(distinct(name)) FROM deleted_users

// Count with Group
users := []User{
  {Name: "name1"},
  {Name: "name2"},
  {Name: "name3"},
  {Name: "name3"},
}

DB.
```

`Assign` attributes to the record regardless it is found or not, and save them back to the database.

```go
Find(&users). Pluck("age", &ages)

var names []string
db. Pluck("name", &names)

db. Table("deleted_users"). Pluck("name", &names)

// Distinct Pluck
DB. Distinct(). Pluck("Name", &names)
// SELECT DISTINCT `name` FROM `users`

// Requesting more than one column, use `Scan` or `Find` like this:
db. Scan(&users)
db. Find(&users)
```

## Optimizer/Index Hints

Optimizer hints allow us to control the query optimizer to choose a certain query execution plan.

```go
import "gorm.io/hints"

DB. UseIndex("idx_user_name")). Find(&User{})
// SELECT * FROM `users` USE INDEX (`idx_user_name`)

DB.
```

Index hints allow passing index hints to the database in case the query planner gets confused.

```go
Or("name = ?", "jinzhu 2"). Count(&count)
// SELECT count(*) FROM users WHERE name = 'jinzhu' OR name = 'jinzhu 2'

db. Count(&count)
// SELECT count(*) FROM users WHERE name = 'jinzhu'; (count)

db.
```

Refer [Optimizer Hints/Index/Comment](hints.html) for more details

## Iteration

GORM supports iterating through Rows

```go
Distinct(). Pluck("Name", &names)
// SELECT DISTINCT `name` FROM `users`

// Requesting more than one column, use `Scan` or `Find` like this:
db. Scan(&users)
db. Find(&users)
```

## FindInBatches

Query and process records in batch

```go
// batch size 100
result := DB. Where("processed = ?", false). FindInBatches(&results, 100, func(tx *gorm.DB, batch int) error {
  for _, result := range results {
    // batch processing found records
  }

  tx. Save(&results)

  tx. RowsAffected // number of records in this batch

  batch // Batch 1, 2, 3

  // returns error will stop future batches
  return nil
})

result. Error // returned error
result. RowsAffected // processed records count in all batches
```

## Query Hooks

GORM allows hooks `AfterFind` for a query, it will be called when querying a record, refer [Hooks](hooks.html) for details

```go
func (u *User) AfterFind(tx *gorm.DB) (err error) {
  if u. Role == "" {
    u. Role = "user"
  }
  return
}
```

## <span id="pluck">Pluck</span>

Query single column from database and scan into a slice, if you want to query multiple columns, use [`Scan`](#scan) instead

```go
var count int64
db. Or("name = ?", "jinzhu 2"). Count(&count)
// SELECT count(*) FROM users WHERE name = 'jinzhu' OR name = 'jinzhu 2'

db. Count(&count)
// SELECT count(*) FROM users WHERE name = 'jinzhu'; (count)

db. Count(&count)
// SELECT count(*) FROM deleted_users;

// Count with Distinct
DB. Distinct("name"). Count(&count)
// SELECT COUNT(DISTINCT(`name`)) FROM `users`

db. Select("count(distinct(name))"). Count(&count)
// SELECT count(distinct(name)) FROM deleted_users

// Count with Group
users := []User{
  {Name: "name1"},
  {Name: "name2"},
  {Name: "name3"},
  {Name: "name3"},
}

DB.
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

## <span id="count">Count</span>

Get matched records count

```go
var count int64
db. Or("name = ?", "jinzhu 2"). Count(&count)
// SELECT count(*) FROM users WHERE name = 'jinzhu' OR name = 'jinzhu 2'

db. Count(&count)
// SELECT count(*) FROM users WHERE name = 'jinzhu'; (count)

db. Count(&count)
// SELECT count(*) FROM deleted_users;

// Count with Distinct
DB. Distinct("name"). Count(&count)
// SELECT COUNT(DISTINCT(`name`)) FROM `users`

db. Select("count(distinct(name))"). Count(&count)
// SELECT count(distinct(name)) FROM deleted_users

// Count with Group
users := []User{
  {Name: "name1"},
  {Name: "name2"},
  {Name: "name3"},
  {Name: "name3"},
}

DB.
```
