---
title: Zaawansowane zapytanie
layout: strona
---

## <span id="smart_select">Inteligentne wyciąganie pól</span>

In GORM, you can efficiently select specific fields using the [`Select`](query.html) method. This is particularly useful when dealing with large models but requiring only a subset of fields, especially in API responses.

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

// GORM will automatically select `id`, `name` fields when querying
db.Model(&User{}).Limit(10).Find(&APIUser{})
// SQL: SELECT `id`, `name` FROM `users` LIMIT 10
```

{% note warn %}
**NOTE** In `QueryFields` mode, all model fields are selected by their names.
{% endnote %}

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  QueryFields: true,
})

// Default behavior with QueryFields set to true
db.Find(&user)
// SQL: SELECT `users`.`name`, `users`.`age`, ... FROM `users`

// Using Session Mode with QueryFields
db.Session(&gorm.Session{QueryFields: true}).Find(&user)
// SQL: SELECT `users`.`name`, `users`.`age`, ... FROM `users`
```

## Locking

GORM wspiera różne typy blokad, na przykład:

```go
// Basic FOR UPDATE lock
db.Clauses(clause.Locking{Strength: "UPDATE"}).Find(&users)
// SQL: SELECT * FROM `users` FOR UPDATE
```

The above statement will lock the selected rows for the duration of the transaction. This can be used in scenarios where you are preparing to update the rows and want to prevent other transactions from modifying them until your transaction is complete.

The `Strength` can be also set to `SHARE` which locks the rows in a way that allows other transactions to read the locked rows but not to update or delete them.
```go
db.Clauses(clause.Locking{
  Strength: "SHARE",
  Table: clause.Table{Name: clause.CurrentTable},
}).Find(&users)
// SQL: SELECT * FROM `users` FOR SHARE OF `users`
```

The `Table` option can be used to specify the table to lock. This is useful when you are joining multiple tables and want to lock only one of them.

Options can be provided like `NOWAIT` which  tries to acquire a lock and fails immediately with an error if the lock is not available. It prevents the transaction from waiting for other transactions to release their locks.

```go
db.Clauses(clause.Locking{
  Strength: "UPDATE",
  Options: "NOWAIT",
}).Find(&users)
// SQL: SELECT * FROM `users` FOR UPDATE NOWAIT
```

Another option can be `SKIP LOCKED` which skips over any rows that are already locked by other transactions. This is useful in high concurrency situations where you want to process rows that are not currently locked by other transactions.

For more advanced locking strategies, refer to [Raw SQL and SQL Builder](sql_builder.html).

## Podzapytania

Subqueries are a powerful feature in SQL, allowing nested queries. GORM can generate subqueries automatically when using a *gorm.DB object as a parameter.

```go
// Simple subquery
db.Where("amount > (?)", db.Table("orders").Select("AVG(amount)")).Find(&orders)
// SQL: SELECT * FROM "orders" WHERE amount > (SELECT AVG(amount) FROM "orders");

// Nested subquery
subQuery := db.Select("AVG(age)").Where("name LIKE ?", "name%").Table("users")
db.Select("AVG(age) as avgage").Group("name").Having("AVG(age) > (?)", subQuery).Find(&results)
// SQL: SELECT AVG(age) as avgage FROM `users` GROUP BY `name` HAVING AVG(age) > (SELECT AVG(age) FROM `users` WHERE name LIKE "name%")
```

### <span id="from_subquery">From SubQuery</span>

GORM allows the use of subqueries in the FROM clause, enabling complex queries and data organization.

```go
// Using subquery in FROM clause
db.Table("(?) as u", db.Model(&User{}).Select("name", "age")).Where("age = ?", 18).Find(&User{})
// SQL: SELECT * FROM (SELECT `name`,`age` FROM `users`) as u WHERE `age` = 18

// Combining multiple subqueries in FROM clause
subQuery1 := db.Model(&User{}).Select("name")
subQuery2 := db.Model(&Pet{}).Select("name")
db.Table("(?) as u, (?) as p", subQuery1, subQuery2).Find(&User{})
// SQL: SELECT * FROM (SELECT `name` FROM `users`) as u, (SELECT `name` FROM `pets`) as p
```

## <span id="group_conditions">Group Conditions</span>

Group Conditions in GORM provide a more readable and maintainable way to write complex SQL queries involving multiple conditions.

```go
// Complex SQL query using Group Conditions
db.Where(
  db.Where("pizza = ?", "pepperoni").Where(db.Where("size = ?", "small").Or("size = ?", "medium")),
).Or(
  db.Where("pizza = ?", "hawaiian").Where("size = ?", "xlarge"),
).Find(&Pizza{})
// SQL: SELECT * FROM `pizzas` WHERE (pizza = "pepperoni" AND (size = "small" OR size = "medium")) OR (pizza = "hawaiian" AND size = "xlarge")
```

## IN z wieloma kolumnami

GORM supports the IN clause with multiple columns, allowing you to filter data based on multiple field values in a single query.

```go
// Using IN with multiple columns
db.Where("(name, age, role) IN ?", [][]interface{}{{"jinzhu", 18, "admin"}, {"jinzhu2", 19, "user"}}).Find(&users)
// SQL: SELECT * FROM users WHERE (name, age, role) IN (("jinzhu", 18, "admin"), ("jinzhu 2", 19, "user"));
```

## Nazwane argumenty

GORM enhances the readability and maintainability of SQL queries by supporting named arguments. This feature allows for clearer and more organized query construction, especially in complex queries with multiple parameters. Named arguments can be utilized using either [`sql.NamedArg`](https://tip.golang.org/pkg/database/sql/#NamedArg) or `map[string]interface{}{}`, providing flexibility in how you structure your queries.

```go
// Example using sql.NamedArg for named arguments
db.Where("name1 = @name OR name2 = @name", sql.Named("name", "jinzhu")).Find(&user)
// SQL: SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu"

// Example using a map for named arguments
db.Where("name1 = @name OR name2 = @name", map[string]interface{}{"name": "jinzhu"}).First(&user)
// SQL: SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu" ORDER BY `users`.`id` LIMIT 1
```

For more examples and details, see [Raw SQL and SQL Builder](sql_builder.html#named_argument)

## Find To Map

GORM provides flexibility in querying data by allowing results to be scanned into a `map[string]interface{}` or `[]map[string]interface{}`, which can be useful for dynamic data structures.

When using `Find To Map`, it's crucial to include `Model` or `Table` in your query to explicitly specify the table name. This ensures that GORM understands which table to query against.

```go
// Scanning the first result into a map with Model
result := map[string]interface{}{}
db.Model(&User{}).First(&result, "id = ?", 1)
// SQL: SELECT * FROM `users` WHERE id = 1 LIMIT 1

// Scanning multiple results into a slice of maps with Table
var results []map[string]interface{}
db.Table("users").Find(&results)
// SQL: SELECT * FROM `users`
```

## FirstOrInit

GORM's `FirstOrInit` method is utilized to fetch the first record that matches given conditions, or initialize a new instance if no matching record is found. This method is compatible with both struct and map conditions and allows additional flexibility with the `Attrs` and `Assign` methods.

```go
// If no User with the name "non_existing" is found, initialize a new User
var user User
db.FirstOrInit(&user, User{Name: "non_existing"})
// user -> User{Name: "non_existing"} if not found

// Retrieving a user named "jinzhu"
db.Where(User{Name: "jinzhu"}).FirstOrInit(&user)
// user -> User{ID: 111, Name: "Jinzhu", Age: 18} if found

// Using a map to specify the search condition
db.FirstOrInit(&user, map[string]interface{}{"name": "jinzhu"})
// user -> User{ID: 111, Name: "Jinzhu", Age: 18} if found
```

### Using `Attrs` for Initialization

When no record is found, you can use `Attrs` to initialize a struct with additional attributes. These attributes are included in the new struct but are not used in the SQL query.

```go
// If no User is found, initialize with given conditions and additional attributes
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrInit(&user)
// SQL: SELECT * FROM USERS WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// user -> User{Name: "non_existing", Age: 20} if not found

// If a User named "Jinzhu" is found, `Attrs` are ignored
db.Where(User{Name: "Jinzhu"}).Attrs(User{Age: 20}).FirstOrInit(&user)
// SQL: SELECT * FROM USERS WHERE name = 'Jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "Jinzhu", Age: 18} if found
```

### Using `Assign` for Attributes

The `Assign` method allows you to set attributes on the struct regardless of whether the record is found or not. These attributes are set on the struct but are not used to build the SQL query and the final data won't be saved into the database.

```go
// Initialize with given conditions and Assign attributes, regardless of record existence
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrInit(&user)
// user -> User{Name: "non_existing", Age: 20} if not found

// If a User named "Jinzhu" is found, update the struct with Assign attributes
db.Where(User{Name: "Jinzhu"}).Assign(User{Age: 20}).FirstOrInit(&user)
// SQL: SELECT * FROM USERS WHERE name = 'Jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "Jinzhu", Age: 20} if found
```

`FirstOrInit`, along with `Attrs` and `Assign`, provides a powerful and flexible way to ensure a record exists and is initialized or updated with specific attributes in a single step.

## FirstOrCreate

`FirstOrCreate` in GORM is used to fetch the first record that matches given conditions or create a new one if no matching record is found. This method is effective with both struct and map conditions. The `RowsAffected` property is useful to determine the number of records created or updated.

```go
// Create a new record if not found
result := db.FirstOrCreate(&user, User{Name: "non_existing"})
// SQL: INSERT INTO "users" (name) VALUES ("non_existing");
// user -> User{ID: 112, Name: "non_existing"}
// result.RowsAffected // => 1 (record created)

// If the user is found, no new record is created
result = db.Where(User{Name: "jinzhu"}).FirstOrCreate(&user)
// user -> User{ID: 111, Name: "jinzhu", Age: 18}
// result.RowsAffected // => 0 (no record created)
```

### Using `Attrs` with FirstOrCreate

`Attrs` can be used to specify additional attributes for the new record if it is not found. These attributes are used for creation but not in the initial search query.

```go
// Create a new record with additional attributes if not found
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrCreate(&user)
// SQL: SELECT * FROM users WHERE name = 'non_existing';
// SQL: INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
// user -> User{ID: 112, Name: "non_existing", Age: 20}

// If the user is found, `Attrs` are ignored
db.Where(User{Name: "jinzhu"}).Attrs(User{Age: 20}).FirstOrCreate(&user)
// SQL: SELECT * FROM users WHERE name = 'jinzhu';
// user -> User{ID: 111, Name: "jinzhu", Age: 18}
```

### Using `Assign` with FirstOrCreate

The `Assign` method sets attributes on the record regardless of whether it is found or not, and these attributes are saved back to the database.

```go
// Initialize and save new record with `Assign` attributes if not found
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrCreate(&user)
// SQL: SELECT * FROM users WHERE name = 'non_existing';
// SQL: INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
// user -> User{ID: 112, Name: "non_existing", Age: 20}

// Update found record with `Assign` attributes
db.Where(User{Name: "jinzhu"}).Assign(User{Age: 20}).FirstOrCreate(&user)
// SQL: SELECT * FROM users WHERE name = 'jinzhu';
// SQL: UPDATE users SET age=20 WHERE id = 111;
// user -> User{ID: 111, Name: "Jinzhu", Age: 20}
```

## Optimizer/Index Hints

GORM includes support for optimizer and index hints, allowing you to influence the query optimizer's execution plan. This can be particularly useful in optimizing query performance or when dealing with complex queries.

Optimizer hints are directives that suggest how a database's query optimizer should execute a query. GORM facilitates the use of optimizer hints through the gorm.io/hints package.

```go
import "gorm.io/hints"

// Using an optimizer hint to set a maximum execution time
db.Clauses(hints.New("MAX_EXECUTION_TIME(10000)")).Find(&User{})
// SQL: SELECT * /*+ MAX_EXECUTION_TIME(10000) */ FROM `users`
```

### Index Hints

Index hints provide guidance to the database about which indexes to use. They can be beneficial if the query planner is not selecting the most efficient indexes for a query.

```go
import "gorm.io/hints"

// Suggesting the use of a specific index
db.Clauses(hints.UseIndex("idx_user_name")).Find(&User{})
// SQL: SELECT * FROM `users` USE INDEX (`idx_user_name`)

// Forcing the use of certain indexes for a JOIN operation
db.Clauses(hints.ForceIndex("idx_user_name", "idx_user_id").ForJoin()).Find(&User{})
// SQL: SELECT * FROM `users` FORCE INDEX FOR JOIN (`idx_user_name`,`idx_user_id`)
```

These hints can significantly impact query performance and behavior, especially in large databases or complex data models. For more detailed information and additional examples, refer to [Optimizer Hints/Index/Comment](hints.html) in the GORM documentation.

## Iteracja

GORM supports the iteration over query results using the `Rows` method. This feature is particularly useful when you need to process large datasets or perform operations on each record individually.

You can iterate through rows returned by a query, scanning each row into a struct. This method provides granular control over how each record is handled.

```go
rows, err := db.Model(&User{}).Where("name = ?", "jinzhu").Rows()
defer rows.Close()

for rows.Next() {
  var user User
  // ScanRows scans a row into a struct
  db.ScanRows(rows, &user)

  // Perform operations on each user
}
```

This approach is ideal for complex data processing that cannot be easily achieved with standard query methods.

## FindInBatches

`FindInBatches` allows querying and processing records in batches. This is especially useful for handling large datasets efficiently, reducing memory usage and improving performance.

With `FindInBatches`, GORM processes records in specified batch sizes. Inside the batch processing function, you can apply operations to each batch of records.

```go
// Processing records in batches of 100
result := db.Where("processed = ?", false).FindInBatches(&results, 100, func(tx *gorm.DB, batch int) error {
  for _, result := range results {
    // Operations on each record in the batch
  }

  // Save changes to the records in the current batch
  tx.Save(&results)

  // tx.RowsAffected provides the count of records in the current batch
  // The variable 'batch' indicates the current batch number

  // Returning an error will stop further batch processing
  return nil
})

// result.Error contains any errors encountered during batch processing
// result.RowsAffected provides the count of all processed records across batches
```

`FindInBatches` is an effective tool for processing large volumes of data in manageable chunks, optimizing resource usage and performance.

## Query Hooks

GORM offers the ability to use hooks, such as `AfterFind`, which are triggered during the lifecycle of a query. These hooks allow for custom logic to be executed at specific points, such as after a record has been retrieved from the databas.

This hook is useful for post-query data manipulation or default value settings. For more detailed information and additional hook types, refer to [Hooks](hooks.html) in the GORM documentation.

```go
func (u *User) AfterFind(tx *gorm.DB) (err error) {
  // Custom logic after finding a user
  if u.Role == "" {
    u.Role = "user" // Set default role if not specified
  }
  return
}

// Usage of AfterFind hook happens automatically when a User is queried
```

## <span id="pluck">Pluck</span>

The `Pluck` method in GORM is used to query a single column from the database and scan the result into a slice. This method is ideal for when you need to retrieve specific fields from a model.

If you need to query more than one column, you can use `Select` with [Scan](query.html) or [Find](query.html) instead.

```go
// Retrieving ages of all users
var ages []int64
db.Model(&User{}).Pluck("age", &ages)

// Retrieving names of all users
var names []string
db.Model(&User{}).Pluck("name", &names)

// Retrieving names from a different table
db.Table("deleted_users").Pluck("name", &names)

// Using Distinct with Pluck
db.Model(&User{}).Distinct().Pluck("Name", &names)
// SQL: SELECT DISTINCT `name` FROM `users`

// Querying multiple columns
db.Select("name", "age").Scan(&users)
db.Select("name", "age").Find(&users)
```

## Scopes

`Scopes` in GORM are a powerful feature that allows you to define commonly-used query conditions as reusable methods. These scopes can be easily referenced in your queries, making your code more modular and readable.

### Defining Scopes

`Scopes` are defined as functions that modify and return a `gorm.DB` instance. You can define a variety of conditions as scopes based on your application's requirements.

```go
// Scope for filtering records where amount is greater than 1000
func AmountGreaterThan1000(db *gorm.DB) *gorm.DB {
  return db.Where("amount > ?", 1000)
}

// Scope for orders paid with a credit card
func PaidWithCreditCard(db *gorm.DB) *gorm.DB {
  return db.Where("pay_mode_sign = ?", "C")
}

// Scope for orders paid with cash on delivery (COD)
func PaidWithCod(db *gorm.DB) *gorm.DB {
  return db.Where("pay_mode_sign = ?", "C")
}

// Scope for filtering orders by status
func OrderStatus(status []string) func(db *gorm.DB) *gorm.DB {
  return func(db *gorm.DB) *gorm.DB {
    return db.Where("status IN (?)", status)
  }
}
```

### Applying Scopes in Queries

You can apply one or more scopes to a query by using the `Scopes` method. This allows you to chain multiple conditions dynamically.

```go
// Applying scopes to find all credit card orders with an amount greater than 1000
db.Scopes(AmountGreaterThan1000, PaidWithCreditCard).Find(&orders)

// Applying scopes to find all COD orders with an amount greater than 1000
db.Scopes(AmountGreaterThan1000, PaidWithCod).Find(&orders)

// Applying scopes to find all orders with specific statuses and an amount greater than 1000
db.Scopes(AmountGreaterThan1000, OrderStatus([]string{"paid", "shipped"})).Find(&orders)
```

`Scopes` are a clean and efficient way to encapsulate common query logic, enhancing the maintainability and readability of your code. For more detailed examples and usage, refer to [Scopes](scopes.html) in the GORM documentation.

## <span id="count">Count</span>

The `Count` method in GORM is used to retrieve the number of records that match a given query. It's a useful feature for understanding the size of a dataset, particularly in scenarios involving conditional queries or data analysis.

### Getting the Count of Matched Records

You can use `Count` to determine the number of records that meet specific criteria in your queries.

```go
var count int64

// Counting users with specific names
db.Model(&User{}).Where("name = ?", "jinzhu").Or("name = ?", "jinzhu 2").Count(&count)
// SQL: SELECT count(1) FROM users WHERE name = 'jinzhu' OR name = 'jinzhu 2'

// Counting users with a single name condition
db.Model(&User{}).Where("name = ?", "jinzhu").Count(&count)
// SQL: SELECT count(1) FROM users WHERE name = 'jinzhu'

// Counting records in a different table
db.Table("deleted_users").Count(&count)
// SQL: SELECT count(1) FROM deleted_users
```

### Count with Distinct and Group

GORM also allows counting distinct values and grouping results.

```go
// Counting distinct names
db.Model(&User{}).Distinct("name").Count(&count)
// SQL: SELECT COUNT(DISTINCT(`name`)) FROM `users`

// Counting distinct values with a custom select
db.Table("deleted_users").Select("count(distinct(name))").Count(&count)
// SQL: SELECT count(distinct(name)) FROM deleted_users

// Counting grouped records
users := []User{
  {Name: "name1"},
  {Name: "name2"},
  {Name: "name3"},
  {Name: "name3"},
}

db.Model(&User{}).Group("name").Count(&count)
// Count after grouping by name
// count => 3
```
