---
title: Query
layout: page
---

## Retrieving a single object

GORM provides `First`, `Take`, `Last` method to retrieve a single object from the database, it adds `LIMIT 1` condition when querying the database, and it will return error `ErrRecordNotFound` if no record found.

```go
// Get the first record ordered by primary key
db.First(&user)
// SELECT * FROM users ORDER BY id LIMIT 1;

// Get one record, no specified order
db.Take(&user)
// SELECT * FROM users LIMIT 1;

// Get last record, order by primary key desc
db.Last(&user)
// SELECT * FROM users ORDER BY id DESC LIMIT 1;

result := db.First(&user)
result.RowsAffected // returns found records count
result.Error        // returns error

// check error ErrRecordNotFound
errors.Is(result.Error, gorm.ErrRecordNotFound)
```

## Retrieving objects

```go
Scan(&result{})
// SELECT users.name, emails.email FROM `users` left join emails on emails.user_id = users.id

rows, err := db. Rows()
for rows. Next() {
  ...
```

## Conditions

### String Conditions

```go
// Get first matched record
db.Where("name = ?", "jinzhu").First(&user)
// SELECT * FROM users WHERE name = 'jinzhu' ORDER BY id LIMIT 1;

// Get all matched records
db.Where("name <> ?", "jinzhu").Find(&users)
// SELECT * FROM users WHERE name <> 'jinzhu';

// IN
db.Where("name IN ?", []string{"jinzhu", "jinzhu 2"}).Find(&users)
// SELECT * FROM users WHERE name IN ('jinzhu','jinzhu 2');

// LIKE
db.Where("name LIKE ?", "%jin%").Find(&users)
// SELECT * FROM users WHERE name LIKE '%jin%';

// AND
db.Where("name = ? Where(&User{Name: "jinzhu", Age: 0}). Find(&users)
// SELECT * FROM users WHERE name = "jinzhu";
```

### Struct & Map Conditions

```go
db. Order("age desc, name"). Find(&users)
// SELECT * FROM users ORDER BY age desc, name;

// Multiple orders
db. Order("age desc"). Order("name"). Find(&users)
// SELECT * FROM users ORDER BY age desc, name;
```

**NOTE** When querying with struct, GORM will only query with non-zero fields, that means if your field's value is `0`, `''`, `false` or other [zero values](https://tour.golang.org/basics/12), it won't be used to build query conditions, for example:

```go
db. Joins("Company"). Find(&users)
// SELECT `users`.`id`,`users`.`name`,`users`.`age`,`Company`.`id` AS `Company__id`,`Company`.`name` AS `Company__name` FROM `users` LEFT JOIN `companies` AS `Company` ON `users`.`company_id` = `Company`.`id`;
```

You can use map to build query conditions, e.g:

```go
db. Distinct("name", "age"). Order("name, age desc"). Find(&results)
```

### <span id="inline_conditions">Inline Condition</span>

Works similar to `Where`.

```go
First(&result)
// SELECT name, sum(age) as total FROM `users` WHERE name LIKE "group%" GROUP BY `name`


db. Having("name = ?", "group"). Find(&result)
// SELECT name, sum(age) as total FROM `users` GROUP BY `name` HAVING name = "group"

rows, err := db. }

rows, err := db. Find(&users)
// SELECT * FROM users ORDER BY age desc, name;

// Multiple orders
db. Order("age desc"). Order("name"). Find(&users)
// SELECT * FROM users ORDER BY age desc, name;
```

### Not Conditions

Build NOT conditions, works similar to `Where`

```go
Scan(&result{})
// SELECT users.name, emails.email FROM `users` left join emails on emails.user_id = users.id

rows, err := db. Rows()
for rows. Next() {
  ... }

db. Scan(&results)

// multiple joins with parameter
db. Joins("JOIN emails ON emails.user_id = users.id AND emails.email = ?", "jinzhu@example.org"). Joins("JOIN credit_cards ON credit_cards.user_id = users.id"). Where("credit_cards.number = ?", "411111111111"). Find(&user)
```

### Or Conditions

```go
db.Where("role = ?", "admin").Or("role = ?", "super_admin").Find(&users)
// SELECT * FROM users WHERE role = 'admin' OR role = 'super_admin';

// Struct
db.Where("name = 'jinzhu'").Or(User{Name: "jinzhu 2", Age: 18}).Find(&users)
// SELECT * FROM users WHERE name = 'jinzhu' OR (name = 'jinzhu 2' AND age = 18);

// Map
db.Where("name = 'jinzhu'").Or(map[string]interface{}{"name": "jinzhu 2", "age": 18}).Find(&users)
// SELECT * FROM users WHERE name = 'jinzhu' OR (name = 'jinzhu 2' AND age = 18);
```

Also check out [Group Conditions in Advanced Query](advanced_query.html#group_conditions), it can be used to write complicated SQL

## Selecting Specific Fields

Specify fields that you want to retrieve from database, by default, select all fields

```go
db. Distinct("name", "age"). Order("name, age desc"). Find(&results)
```

Also check out [Smart Select Fields](advanced_query.html#smart_select)

## Order

Specify order when retrieving records from the database

```go
db. Distinct("name", "age"). Order("name, age desc"). Find(&results)
```

## Limit & Offset

`Limit` specify the max number of records to retrieve `Offset` specify the number of records to skip before starting to return the records

```go
db. Limit(3). Find(&users)
// SELECT * FROM users LIMIT 3;

// Cancel limit condition with -1
db. Limit(-1). Find(&users2)
// SELECT * FROM users LIMIT 10; (users1)
// SELECT * FROM users; (users2)

db. Offset(3). Find(&users)
// SELECT * FROM users OFFSET 3;

db. Offset(5). Find(&users)
// SELECT * FROM users OFFSET 5 LIMIT 10;

// Cancel offset condition with -1
db. Offset(10). Offset(-1). Find(&users2)
// SELECT * FROM users OFFSET 10; (users1)
// SELECT * FROM users; (users2)
```

Checkout [Pagination](scopes.html#pagination) for how to make a paginator

## Group & Having

```go
type result struct {
  Name  string
  Email string
}
db. Model(&User{}). Scan(&result{})
// SELECT users.name, emails.email FROM `users` left join emails on emails.user_id = users.id

rows, err := db. Rows()
for rows. Next() {
  ... }

db. Scan(&results)

// multiple joins with parameter
db. Joins("JOIN emails ON emails.user_id = users.id AND emails.email = ?", "jinzhu@example.org"). Joins("JOIN credit_cards ON credit_cards.user_id = users.id"). Where("credit_cards.number = ?", "411111111111"). Find(&user)
First(&result)
// SELECT name, sum(age) as total FROM `users` WHERE name LIKE "group%" GROUP BY `name`


db. Having("name = ?", "group"). Find(&result)
// SELECT name, sum(age) as total FROM `users` GROUP BY `name` HAVING name = "group"

rows, err := db. }

rows, err := db. }

type Result struct {
  Date  time.
type result struct {
  Date  time. Time
  Total int
}

db. Where("name LIKE ?", "group%"). First(&result)
// SELECT name, sum(age) as total FROM `users` WHERE name LIKE "group%" GROUP BY `name`


db. Having("name = ?", "group"). Find(&result)
// SELECT name, sum(age) as total FROM `users` GROUP BY `name` HAVING name = "group"

rows, err := db. }

rows, err := db. }

type Result struct {
  Date  time. Time
  Total int64
}
db.
```

## Distinct

Selecting distinct values from the model

```go
db. Distinct("name", "age"). Order("name, age desc"). Find(&results)
```

`Distinct` works with [`Pluck`](advanced_query.html#pluck), [`Count`](advanced_query.html#count) also

## Joins

Specify Joins conditions

```go
type result struct {
  Name  string
  Email string
}
db. Model(&User{}). Scan(&result{})
// SELECT users.name, emails.email FROM `users` left join emails on emails.user_id = users.id

rows, err := db. Rows()
for rows. Next() {
  ... }

db. Scan(&results)

// multiple joins with parameter
db. Joins("JOIN emails ON emails.user_id = users.id AND emails.email = ?", "jinzhu@example.org").
db. Joins("Company"). Find(&users)
// SELECT `users`.`id`,`users`.`name`,`users`.`age`,`Company`.`id` AS `Company__id`,`Company`.`name` AS `Company__name` FROM `users` LEFT JOIN `companies` AS `Company` ON `users`.`company_id` = `Company`.`id`;
```

### Joins Preloading

You can use `Joins` eager loading associations with a single SQL, for example:

```go
db. Joins("Company"). Find(&users)
// SELECT `users`.`id`,`users`.`name`,`users`.`age`,`Company`.`id` AS `Company__id`,`Company`.`name` AS `Company__name` FROM `users` LEFT JOIN `companies` AS `Company` ON `users`.`company_id` = `Company`.`id`;
```

Refer [Preloading (Eager Loading)](preload.html) for details

## <span id="scan">Scan</span>

Scan results into a struct work similar to `Find`

```go
Having("name = ?", "group"). Find(&result)
// SELECT name, sum(age) as total FROM `users` GROUP BY `name` HAVING name = "group"

rows, err := db. }

rows, err := db. }

type Result struct {
  Date  time. Time
  Total int64
}
db. Scan(&results)
```
