---
title: Gen Query
layout: page
---

## Retrieving a single object

Generated code provides `First`, `Take`, `Last` methods to retrieve a single object from the database, it adds `LIMIT 1` condition when querying the database, and it will return the error `ErrRecordNotFound` if no record is found.

```go
u := query.User

// Get the first record ordered by primary key
user, err := u.WithContext(ctx).First()
// SELECT * FROM users ORDER BY id LIMIT 1;

// Get one record, no specified order
user, err := u.WithContext(ctx).Take()
// SELECT * FROM users LIMIT 1;

// Get last record, ordered by primary key desc
user, err := u.WithContext(ctx).Last()
// SELECT * FROM users ORDER BY id DESC LIMIT 1;

// select by write db
user, err := u.WithContext(ctx).WriteDB().Last()

// check error ErrRecordNotFound
errors.Is(err, gorm.ErrRecordNotFound)
```

### Retrieving objects with primary key

```go
u := query.User

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

## Retrieving all objects

```go
u := query.User

// Get all records
users, err := u.WithContext(ctx).Find()
// SELECT * FROM users;
```

## Conditions

### Field Query Interfaces

Gen generates type-safe interfaces each field, you can use them to generate SQL expressions

| Field Type | Supported  Interface                                                                                                                                                                                                              |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| generic    | IsNull/IsNotNull/Count/Eq/Neq/Gt/Gte/Lt/Lte/Like/Value/Sum/IfNull                                                                                                                                                                 |
| int        | Eq/Neq/Gt/Gte/Lt/Lte/In/NotIn/Between/NotBetween/Like/NotLike/Add/Sub/Mul/Div/Mod/FloorDiv/RightShift/LeftShift/BitXor/BitAnd/BitOr/BitFlip/Value/Zero/Sum/IfNull                                                                 |
| uint       | same with int                                                                                                                                                                                                                     |
| float      | Eq/Neq/Gt/Gte/Lt/Lte/In/NotIn/Between/NotBetween/Like/NotLike/Add/Sub/Mul/Div/FloorDiv/Floor/Value/Zero/Sum/IfNull                                                                                                                |
| string     | Eq/Neq/Gt/Gte/Lt/Lte/Between/NotBetween/In/NotIn/Like/NotLike/Regexp/NotRegxp/FindInSet/FindInSetWith/Value/Zero/IfNull                                                                                                           |
| bool       | Not/Is/And/Or/Xor/BitXor/BitAnd/BitOr/Value/Zero                                                                                                                                                                                  |
| time       | Eq/Neq/Gt/Gte/Lt/Lte/Between/NotBetween/In/NotIn/Add/Sub/Date/DateDiff/DateFormat/Now/CurDate/CurTime/DayName/MonthName/Month/Day/Hour/Minute/Second/MicroSecond/DayOfWeek/DayOfMonth/FromDays/FromUnixtime/Value/Zero/Sum/IfNull |

Here are some usage examples:

```go
u := query.User

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

### Not Conditions

Build NOT conditions, works similar to `Where`

```go
u := query.User

user, err := u.WithContext(ctx).Not(u.Name.Eq("modi")).First()
// SELECT * FROM users WHERE NOT name = "modi" ORDER BY id LIMIT 1;

// Not In
users, err := u.WithContext(ctx).Not(u.Name.In("modi", "zhangqiang")).Find()
// SELECT * FROM users WHERE name NOT IN ("modi", "zhangqiang");

// Not In slice of primary keys
user, err := u.WithContext(ctx).Not(u.ID.In(1,2,3)).First()
// SELECT * FROM users WHERE id NOT IN (1,2,3) ORDER BY id LIMIT 1;
```

### Or Conditions

```go
u := query.User

users, err := u.WithContext(ctx).Where(u.Role.Eq("admin")).Or(u.Role.Eq("super_admin")).Find()
// SELECT * FROM users WHERE role = 'admin' OR role = 'super_admin';
```

### Group Conditions

Easier to write complicated SQL query with Group Conditions

```go
p := query.Pizza
pd := p.WithContext(ctx)

pizzas, err := pd.Where(
    pd.Where(p.Pizza.Eq("pepperoni")).
        Where(pd.Where(p.Size.Eq("small")).Or(p.Size.Eq("medium"))),
).Or(
    pd.Where(p.Pizza.Eq("hawaiian")).Where(p.Size.Eq("xlarge")),
).Find()

// SELECT * FROM `pizzas` WHERE (pizza = "pepperoni" AND (size = "small" OR size = "medium")) OR (pizza = "hawaiian" AND size = "xlarge")
```

### Selecting Specific Fields

`Select` allows you to specify the fields that you want to retrieve from database. Otherwise, GORM will select all fields by default.

```go
u := query.User

users, err := u.WithContext(ctx).Select(u.Name, u.Age).Find()
// SELECT name, age FROM users;

u.WithContext(ctx).Select(u.Age.Avg()).Rows()
// SELECT Avg(age) FROM users;
```

### Tuple Query

```go
u := query.User

users, err := u.WithContext(ctx).Where(u.WithContext(ctx).Columns(u.ID, u.Name).In(field.Values([][]interface{}{{1, "modi"}, {2, "zhangqiang"}}))).Find()
// SELECT * FROM `users` WHERE (`id`, `name`) IN ((1,'humodi'),(2,'tom'));
```

### JSON Query

```go
u := query.User

users, err := u.WithContext(ctx).Where(gen.Cond(datatypes.JSONQuery("attributes").HasKey("role"))...).Find()
// SELECT * FROM `users` WHERE JSON_EXTRACT(`attributes`,'$.role') IS NOT NULL;
```

### Order

Specify order when retrieving records from the database

```go
u := query.User

users, err := u.WithContext(ctx).Order(u.Age.Desc(), u.Name).Find()
// SELECT * FROM users ORDER BY age DESC, name;

// Multiple orders
users, err := u.WithContext(ctx).Order(u.Age.Desc()).Order(u.Name).Find()
// SELECT * FROM users ORDER BY age DESC, name;
```

Get field by string

```go
u := query.User

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

### Limit & Offset

`Limit` specify the max number of records to retrieve `Offset` specify the number of records to skip before starting to return the records

```go
u := query.User

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

### Group By & Having

```go
u := query.User

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

o := query.Order

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

### Distinct

Selecting distinct values from the model

```go
u := query.User

users, err := u.WithContext(ctx).Distinct(u.Name, u.Age).Order(u.Name, u.Age.Desc()).Find()
```

`Distinct` works with `Pluck` and `Count` too

### Joins

Specify Joins conditions

```go
q := query
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

### New Field Expiression

Sometimes you may need to create a dynamic field for dynamically SQL generation

| Field Type | Create Function                |
| ---------- | ------------------------------ |
| generic    | NewField                       |
| int        | NewInt/NewInt8/.../NewInt64    |
| uint       | NewUint/NewUint8/.../NewUint64 |
| float      | NewFloat32/NewFloat64          |
| string     | NewString/NewBytes             |
| bool       | NewBool                        |
| time       | NewTime                        |

Usage example:

#### Generic Fields

```go
import "gorm.io/gen/field"

// create a new generic field map to `generic_a`
f := field.NewField("table_name", "generic")
// `table_name`.`generic` IS NULL
f.IsNull()

// compare fields
id := field.NewField("user", "id")
anotherID := field.NewField("another", "id")
// `user`.`id` = `another`.`id`
id.EqCol(anotherID)
```

#### `int/uint/float` Fields

```go
// int field
f := field.NewInt("user", "id")
// `user`.`id` = 123
f.Eq(123)
// `user`.`id` DESC
f.Desc()
// `user`.`id` AS `user_id`
f.As("user_id")
// COUNT(`user`.`id`)
f.Count()
// SUM(`user`.`id`)
f.Sum()
// SUM(`user`.`id`) > 123
f.Sum().Gt(123)
// ((`user`.`id`+1)*2)/3
f.Add(1).Mul(2).Div(3),
// `user`.`id` <<< 3
f.LeftShift(3)
```

#### String Fields

```go
name := field.NewString("user", "name")
// `user`.`name` = "modi"
name.Eq("modi")
// `user`.`name` LIKE %modi%
name.Like("%modi%")
// `user`.`name` REGEXP .*
name.Regexp(".*")
// `user`.`name` FIND_IN_SET(`name`,"modi,jinzhu,zhangqiang")
name.FindInSet("modi,jinzhu,zhangqiang")
// `uesr`.`name` CONCAT("[",name,"]")
name.Concat("[", "]")
```

#### Time Fields

```go
birth := field.NewString("user", "birth")
// `user`.`birth` = ? (now)
birth.Eq(time.Now())
// DATE_ADD(`user`.`birth`, INTERVAL ? MICROSECOND)
birth.Add(time.Duration(time.Hour).Microseconds())
// DATE_FORMAT(`user`.`birth`, "%W %M %Y")
birth.DateFormat("%W %M %Y")
```

#### Bool Fields

```go
active := field.NewBool("user", "active")
// `user`.`active` = TRUE
active.Is(true)
// NOT `user`.`active`
active.Not()
// `user`.`active` AND TRUE
active.And(true)
```

## SubQuery

A subquery can be nested within a query, GEN can generate subquery when using a `Dao` object as param

```go
o := query.Order
u := query.User

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

### From SubQuery

GORM allows you using subquery in FROM clause with method `Table`, for example:

```go
u := query.User
p := query.Pet

users, err := gen.Table(u.WithContext(ctx).Select(u.Name, u.Age).As("u")).Where(u.Age.Eq(18)).Find()
// SELECT * FROM (SELECT `name`,`age` FROM `users`) as u WHERE `age` = 18

subQuery1 := u.WithContext(ctx).Select(u.Name)
subQuery2 := p.WithContext(ctx).Select(p.Name)
users, err := gen.Table(subQuery1.As("u"), subQuery2.As("p")).Find()
db.Table("(?) as u, (?) as p", subQuery1, subQuery2).Find(&User{})
// SELECT * FROM (SELECT `name` FROM `users`) as u, (SELECT `name` FROM `pets`) as p
```
### FirstOrInit

Initialize struct with more attributes if record not found, those `Attrs` won't be used to build the SQL query

```go
// User not found, initialize it with given conditions and Attrs
u.WithContext(ctx).Attrs(field.Attrs(&model.User{Age: 20})).Where(u.Name.Eq("non_existing")).FirstOrInit()
// SELECT * FROM USERS WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// user -> User{Name: "non_existing", Age: 20}

// User not found, initialize it with given conditions and Attrs
u.WithContext(ctx).Attrs(u.Age.Value(20).Where(u.Name.Eq("non_existing")).FirstOrInit()
// SELECT * FROM USERS WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// user -> User{Name: "non_existing", Age: 20}

// Found user with `name` = `gen`, attributes will be ignored
u.WithContext(ctx).Attrs(field.Attrs(&model.User{Age: 20})).Where(u.Name.Eq("gen")).FirstOrInit()
// SELECT * FROM USERS WHERE name = 'gen' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "gen", Age: 18}
```

`Assign` attributes to struct regardless it is found or not, those attributes won't be used to build SQL query and the final data won't be saved into database

```go
// User not found, initialize it with give conditions and Assign attributes
u.WithContext(ctx).Assign(field.Attrs(map[string]interface{}{"age": 20})).Where(u.Name.Eq("non_existing")).FirstOrInit()
// user -> User{Name: "non_existing", Age: 20}

// Found user with `name` = `gen`, update it with Assign attributes
u.WithContext(ctx).Assign(field.Attrs(&model.User{Name: "gen_assign"}).Select(dal.User.ALL)).Where(u.Name.Eq("gen")).FirstOrInit()
// SELECT * FROM USERS WHERE name = gen' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "gen", Age: 20}
```

### FirstOrCreate

Get first matched record or create a new one with given conditions (only works with struct, map conditions), `RowsAffected` returns created/updated record's count

```go

// Found user with `name` = `gen`
result := u.WithContext(ctx).Where(u.Name.Eq(jinzhu)).FirstOrCreate(&user)
// user -> User{ID: 111, Name: "gen", "Age": 18}
// result.RowsAffected // => 0
```

Create struct with more attributes if record not found, those `Attrs` won't be used to build SQL query

```go
// User not found, create it with give conditions and Attrs
u.WithContext(ctx).Attrs(field.Attrs(&model.User{Age: 20})).Where(u.Name.Eq("non_existing")).FirstOrCreate()
// SELECT * FROM users WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
// user -> User{ID: 112, Name: "non_existing", Age: 20}

// Found user with `name` = `gen`, attributes will be ignored
u.WithContext(ctx).Attrs(field.Attrs(&model.User{Age: 20})).Where(u.Name.Eq("gen")).FirstOrCreate()
// SELECT * FROM users WHERE name = 'gen' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "gen", Age: 18}
```

`Assign` attributes to the record regardless it is found or not and save them back to the database.

```go
// User not found, initialize it with give conditions and Assign attributes
u.WithContext(ctx).Assign(field.Attrs(&model.User{Age: 20})).Where(u.Name.Eq("non_existing")).FirstOrCreate()
// SELECT * FROM users WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
// user -> User{ID: 112, Name: "non_existing", Age: 20}

// Found user with `name` = `gen`, update it with Assign attributes
u.WithContext(ctx).Assign(field.Attrs(&model.User{Age: 20})).Where(u.Name.Eq("gen")).FirstOrCreate()
// SELECT * FROM users WHERE name = 'gen' ORDER BY id LIMIT 1;
// UPDATE users SET age=20 WHERE id = 111;
// user -> User{ID: 111, Name: "gen", Age: 20}

// Found user with `name` = `gen`, update it with Assign attributes
u.WithContext(ctx).Assign(u.Age.Value(20)).Where(u.Name.Eq("gen")).FirstOrCreate()
// SELECT * FROM users WHERE name = 'gen' ORDER BY id LIMIT 1;
// UPDATE users SET age=20 WHERE id = 111;
// user -> User{ID: 111, Name: "gen", Age: 20}
```

### Struct & Map Conditions

```go
// Struct
u.WithContext(ctx).Where(field.Attrs(&User{Name: "gen", Age: 20})).First()
// SELECT * FROM users WHERE name = "gen" AND age = 20 ORDER BY id LIMIT 1;

// Map
u.WithContext(ctx).Where(field.Attrs(map[string]interface{}{"name": "gen", "age": 20})).Find()
// SELECT * FROM users WHERE name = "gen" AND age = 20;

```

{% note warn %}
**NOTE** When querying with struct, GORM GEN will only query with non-zero fields, that means if your field's value is `0`, `''`, `false` or other [zero values](https://tour.golang.org/basics/12), it won't be used to build query conditions, for example:
{% endnote %}

```go
u.WithContext(ctx).Where(field.Attrs(&User{Name: "gen", Age: 0})).Find()
// SELECT * FROM users WHERE name = "gen";
```

To include zero values in the query conditions, you can use a map, which will include all key-values as query conditions, for example:

```go
u.WithContext(ctx).Where(field.Attrs(map[string]interface{}{"name": "gen", "age": 0})).Find()
// SELECT * FROM users WHERE name = "gen" AND age = 0;
```

For more details, see [Specify Struct search fields](#specify_search_fields).

### <span id="specify_search_fields">Specify Struct search fields</span>

When searching with struct, you can specify which particular values from the struct to use in the query conditions by passing in the relevant  the dbname to `Attrs()`, for example:

```go
u.WithContext(ctx).Where(field.Attrs(&User{Name: "gen"}).Select(u.Name,u.Age)).Find()
// SELECT * FROM users WHERE name = "gen" AND age = 0;

u.WithContext(ctx).Where(field.Attrs(&User{Name: "gen"}).Select(u.Age)).Find()
// SELECT * FROM users WHERE age = 0;
```
