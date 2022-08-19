---
title: Gen Query
layout: page
---

#### Query

##### Retrieving a single object

Generated code provides `First`, `Take`, `Last` methods to retrieve a single object from the database, it adds `LIMIT 1` condition when querying the database, and it will return the error `ErrRecordNotFound` if no record is found.

```go
u := query.Use(db).User

// Get the first record ordered by primary key
user, err := u.WithContext(ctx).First()
// SELECT * FROM users ORDER BY id LIMIT 1;

// Get one record, no specified order
user, err := u.WithContext(ctx).Take()
// SELECT * FROM users LIMIT 1;

// Get last record, ordered by primary key desc
user, err := u.WithContext(ctx).Last()
// SELECT * FROM users ORDER BY id DESC LIMIT 1;

// check error ErrRecordNotFound
errors.Is(err, gorm.ErrRecordNotFound)
```

##### Retrieving objects with primary key

```go
u := query.Use(db).User

user, err := u.WithContext(ctx).Where(u.ID.Eq(10)).First()
// SELECT * FROM users WHERE id = 10;

users, err := u.WithContext(ctx).Where(u.ID.In(1,2,3)).Find()
// SELECT * FROM users WHERE id IN (1,2,3);
```

If the primary key is a string (for example, like a uuid), the query will be written as follows:

```go
user, err := u.WithContext(ctx).Where(u.ID.Eq("1b74413f-f3b8-409f-ac47-e8c062e3472a")).First()
// SELECT * FROM users WHERE id = "1b74413f-f3b8-409f-ac47-e8c062e3472a";
```

##### Retrieving all objects

```go
u := query.Use(db).User

// Get all records
users, err := u.WithContext(ctx).Find()
// SELECT * FROM users;
```

##### Conditions

###### String Conditions

```go
u := query.Use(db).User

// Get first matched record
user, err := u.WithContext(ctx).Where(u.Name.Eq("modi")).First()
// SELECT * FROM users WHERE name = 'modi' ORDER BY id LIMIT 1;

// Get all matched records
users, err := u.WithContext(ctx).Where(u.Name.Neq("modi")).Find()
// SELECT * FROM users WHERE name <> 'modi';

// IN
users, err := u.WithContext(ctx).Where(u.Name.In("modi", "zhangqiang")).Find()
// SELECT * FROM users WHERE name IN ('modi','zhangqiang');

// LIKE
users, err := u.WithContext(ctx).Where(u.Name.Like("%modi%")).Find()
// SELECT * FROM users WHERE name LIKE '%modi%';

// AND
users, err := u.WithContext(ctx).Where(u.Name.Eq("modi"), u.Age.Gte(17)).Find()
// SELECT * FROM users WHERE name = 'modi' AND age >= 17;

// Time
users, err := u.WithContext(ctx).Where(u.Birthday.Gt(birthTime).Find()
// SELECT * FROM users WHERE birthday > '2000-01-01 00:00:00';

// BETWEEN
users, err := u.WithContext(ctx).Where(u.Birthday.Between(lastWeek, today)).Find()
// SELECT * FROM users WHERE birthday BETWEEN '2000-01-01 00:00:00' AND '2000-01-08 00:00:00';
```

###### Inline Condition

```go
u := query.Use(db).User

// Get by primary key if it were a non-integer type
user, err := u.WithContext(ctx).Where(u.ID.Eq("string_primary_key")).First()
// SELECT * FROM users WHERE id = 'string_primary_key';

// Plain SQL
users, err := u.WithContext(ctx).Where(u.Name.Eq("modi")).Find()
// SELECT * FROM users WHERE name = "modi";

users, err := u.WithContext(ctx).Where(u.Name.Neq("modi"), u.Age.Gt(17)).Find()
// SELECT * FROM users WHERE name <> "modi" AND age > 17;
```

###### Not Conditions

Build NOT conditions, works similar to `Where`

```go
u := query.Use(db).User

user, err := u.WithContext(ctx).Not(u.Name.Eq("modi")).First()
// SELECT * FROM users WHERE NOT name = "modi" ORDER BY id LIMIT 1;

// Not In
users, err := u.WithContext(ctx).Not(u.Name.In("modi", "zhangqiang")).Find()
// SELECT * FROM users WHERE name NOT IN ("modi", "zhangqiang");

// Not In slice of primary keys
user, err := u.WithContext(ctx).Not(u.ID.In(1,2,3)).First()
// SELECT * FROM users WHERE id NOT IN (1,2,3) ORDER BY id LIMIT 1;
```

###### Or Conditions

```go
u := query.Use(db).User

users, err := u.WithContext(ctx).Where(u.Role.Eq("admin")).Or(u.Role.Eq("super_admin")).Find()
// SELECT * FROM users WHERE role = 'admin' OR role = 'super_admin';
```

###### Group Conditions

Easier to write complicated SQL query with Group Conditions

```go
p := query.Use(db).Pizza
pd := p.WithContext(ctx)

pizzas, err := pd.Where(
    pd.Where(p.Pizza.Eq("pepperoni")).
        Where(pd.Where(p.Size.Eq("small")).Or(p.Size.Eq("medium"))),
).Or(
    pd.Where(p.Pizza.Eq("hawaiian")).Where(p.Size.Eq("xlarge")),
).Find()

// SELECT * FROM `pizzas` WHERE (pizza = "pepperoni" AND (size = "small" OR size = "medium")) OR (pizza = "hawaiian" AND size = "xlarge")
```

###### Selecting Specific Fields

`Select` allows you to specify the fields that you want to retrieve from database. Otherwise, GORM will select all fields by default.

```go
u := query.Use(db).User

users, err := u.WithContext(ctx).Select(u.Name, u.Age).Find()
// SELECT name, age FROM users;

u.WithContext(ctx).Select(u.Age.Avg()).Rows()
// SELECT Avg(age) FROM users;
```

###### Tuple Query

```go
u := query.Use(db).User

users, err := u.WithContext(ctx).Where(u.WithContext(ctx).Columns(u.ID, u.Name).In(field.Values([][]interface{}{{1, "modi"}, {2, "zhangqiang"}}))).Find()
// SELECT * FROM `users` WHERE (`id`, `name`) IN ((1,'humodi'),(2,'tom'));
```

###### JSON Query

```go
u := query.Use(db).User

users, err := u.WithContext(ctx).Where(gen.Cond(datatypes.JSONQuery("attributes").HasKey("role"))...).Find()
// SELECT * FROM `users` WHERE JSON_EXTRACT(`attributes`,'$.role') IS NOT NULL;
```

###### Order

Specify order when retrieving records from the database

```go
u := query.Use(db).User

users, err := u.WithContext(ctx).Order(u.Age.Desc(), u.Name).Find()
// SELECT * FROM users ORDER BY age DESC, name;

// Multiple orders
users, err := u.WithContext(ctx).Order(u.Age.Desc()).Order(u.Name).Find()
// SELECT * FROM users ORDER BY age DESC, name;
```

Get field by string

```go
u := query.Use(db).User

orderCol, ok := u.GetFieldByName(orderColStr) // maybe orderColStr == "id"
if !ok {
  // User doesn't contains orderColStr
}

users, err := u.WithContext(ctx).Order(orderCol).Find()
// SELECT * FROM users ORDER BY age;

// OR Desc
users, err := u.WithContext(ctx).Order(orderCol.Desc()).Find()
// SELECT * FROM users ORDER BY age DESC;
```

###### Limit & Offset

`Limit` specify the max number of records to retrieve
`Offset` specify the number of records to skip before starting to return the records

```go
u := query.Use(db).User

urers, err := u.WithContext(ctx).Limit(3).Find()
// SELECT * FROM users LIMIT 3;

// Cancel limit condition with -1
users, err := u.WithContext(ctx).Limit(10).Limit(-1).Find()
// SELECT * FROM users;

users, err := u.WithContext(ctx).Offset(3).Find()
// SELECT * FROM users OFFSET 3;

users, err := u.WithContext(ctx).Limit(10).Offset(5).Find()
// SELECT * FROM users OFFSET 5 LIMIT 10;

// Cancel offset condition with -1
users, err := u.WithContext(ctx).Offset(10).Offset(-1).Find()
// SELECT * FROM users;
```

###### Group By & Having

```go
u := query.Use(db).User

var users []struct {
    Name  string
    Total int
}
err := u.WithContext(ctx).Select(u.Name, u.ID.Count().As("total")).Group(u.Name).Scan(&users)
// SELECT name, count(id) as total FROM `users` GROUP BY `name`

err := u.WithContext(ctx).Select(u.Name, u.Age.Sum().As("total")).Where(u.Name.Like("%modi%")).Group(u.Name).Scan(&users)
// SELECT name, sum(age) as total FROM `users` WHERE name LIKE "%modi%" GROUP BY `name`

err := u.WithContext(ctx).Select(u.Name, u.Age.Sum().As("total")).Group(u.Name).Having(u.Name.Eq("group")).Scan(&users)
// SELECT name, sum(age) as total FROM `users` GROUP BY `name` HAVING name = "group"

rows, err := u.WithContext(ctx).Select(u.Birthday.As("date"), u.Age.Sum().As("total")).Group(u.Birthday).Rows()
for rows.Next() {
  ...
}

o := query.Use(db).Order

rows, err := o.WithContext(ctx).Select(o.CreateAt.Date().As("date"), o.Amount.Sum().As("total")).Group(o.CreateAt.Date()).Having(u.Amount.Sum().Gt(100)).Rows()
for rows.Next() {
  ...
}

var results []struct {
    Date  time.Time
    Total int
}

o.WithContext(ctx).Select(o.CreateAt.Date().As("date"), o.WithContext(ctx).Amount.Sum().As("total")).Group(o.CreateAt.Date()).Having(u.Amount.Sum().Gt(100)).Scan(&results)
```

###### Distinct

Selecting distinct values from the model

```go
u := query.Use(db).User

users, err := u.WithContext(ctx).Distinct(u.Name, u.Age).Order(u.Name, u.Age.Desc()).Find()
```

`Distinct` works with `Pluck` and `Count` too

###### Joins

Specify Joins conditions

```go
q := query.Use(db)
u := q.User
e := q.Email
c := q.CreditCard

type Result struct {
    Name  string
    Email string
    ID    int64
}

var result Result

err := u.WithContext(ctx).Select(u.Name, e.Email).LeftJoin(e, e.UserID.EqCol(u.ID)).Scan(&result)
// SELECT users.name, emails.email FROM `users` left join emails on emails.user_id = users.id

// self join
var result Result
u2 := u.As("u2")
err := u.WithContext(ctx).Select(u.Name, u2.ID).LeftJoin(u2, u2.ID.EqCol(u.ID)).Scan(&result)
// SELECT users.name, u2.id FROM `users` left join `users` u2 on u2.id = users.id

//join with sub query
var result Result
e2 := e.As("e2")
err := u.WithContext(ctx).Select(u.Name, e2.Email).LeftJoin(e.WithContext(ctx).Select(e.Email, e.UserID).Where(e.UserID.Gt(100)).As("e2"), e2.UserID.EqCol(u.ID)).Scan(&result)
// SELECT users.name, e2.email FROM `users` left join (select email,user_id from emails  where user_id > 100) as e2 on e2.user_id = users.id

rows, err := u.WithContext(ctx).Select(u.Name, e.Email).LeftJoin(e, e.UserID.EqCol(u.ID)).Rows()
for rows.Next() {
  ...
}

var results []Result

err := u.WithContext(ctx).Select(u.Name, e.Email).LeftJoin(e, e.UserID.EqCol(u.ID)).Scan(&results)

// multiple joins with parameter
users := u.WithContext(ctx).Join(e, e.UserID.EqCol(u.id), e.Email.Eq("modi@example.org")).Join(c, c.UserID.EqCol(u.ID)).Where(c.Number.Eq("411111111111")).Find()
```

##### SubQuery

A subquery can be nested within a query, GEN can generate subquery when using a `Dao` object as param

```go
o := query.Use(db).Order
u := query.Use(db).User

orders, err := o.WithContext(ctx).Where(o.WithContext(ctx).Columns(o.Amount).Gt(o.WithContext(ctx).Select(o.Amount.Avg())).Find()
// SELECT * FROM "orders" WHERE amount > (SELECT AVG(amount) FROM "orders");

subQuery := u.WithContext(ctx).Select(u.Age.Avg()).Where(u.Name.Like("name%"))
users, err := u.WithContext(ctx).Select(u.Age.Avg().As("avgage")).Group(u.Name).Having(u.WithContext(ctx).Columns(u.Age.Avg()).Gt(subQuery).Find()
// SELECT AVG(age) as avgage FROM `users` GROUP BY `name` HAVING AVG(age) > (SELECT AVG(age) FROM `users` WHERE name LIKE "name%")

// Select users with orders between 100 and 200
subQuery1 := o.WithContext(ctx).Select(o.ID).Where(o.UserID.EqCol(u.ID), o.Amount.Gt(100))
subQuery2 := o.WithContext(ctx).Select(o.ID).Where(o.UserID.EqCol(u.ID), o.Amount.Gt(200))
u.WithContext(ctx).Exists(subQuery1).Not(u.WithContext(ctx).Exists(subQuery2)).Find()
// SELECT * FROM `users` WHERE EXISTS (SELECT `orders`.`id` FROM `orders` WHERE `orders`.`user_id` = `users`.`id` AND `orders`.`amount` > 100 AND `orders`.`deleted_at` IS NULL) AND NOT EXISTS (SELECT `orders`.`id` FROM `orders` WHERE `orders`.`user_id` = `users`.`id` AND `orders`.`amount` > 200 AND `orders`.`deleted_at` IS NULL) AND `users`.`deleted_at` IS NULL
```

###### From SubQuery

GORM allows you using subquery in FROM clause with method `Table`, for example:

```go
u := query.Use(db).User
p := query.Use(db).Pet

users, err := gen.Table(u.WithContext(ctx).Select(u.Name, u.Age).As("u")).Where(u.Age.Eq(18)).Find()
// SELECT * FROM (SELECT `name`,`age` FROM `users`) as u WHERE `age` = 18

subQuery1 := u.WithContext(ctx).Select(u.Name)
subQuery2 := p.WithContext(ctx).Select(p.Name)
users, err := gen.Table(subQuery1.As("u"), subQuery2.As("p")).Find()
db.Table("(?) as u, (?) as p", subQuery1, subQuery2).Find(&User{})
// SELECT * FROM (SELECT `name` FROM `users`) as u, (SELECT `name` FROM `pets`) as p
```

