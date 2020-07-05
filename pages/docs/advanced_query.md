---
title: Advanced Query
layout: page
---

# Small struct

# select for update locking

# find to map

# pluck

# join, preloading

# subquery

SubQuery with `*gorm.expr`

```go
db.Where("amount > ?", db.Table("orders").Select("AVG(amount)").Where("state = ?", "paid").SubQuery()).Find(&orders)
// SELECT * FROM "orders"  WHERE "orders"."deleted_at" IS NULL AND (amount > (SELECT AVG(amount) FROM "orders"  WHERE (state = 'paid')));
```


# group conditions

# first or int

## FirstOrInit

Get first matched record, or initalize a new one with given conditions (only works with struct, map conditions)

```go
// Unfound
db.FirstOrInit(&user, User{Name: "non_existing"})
//// user -> User{Name: "non_existing"}

// Found
db.Where(User{Name: "Jinzhu"}).FirstOrInit(&user)
//// user -> User{Id: 111, Name: "Jinzhu", Age: 20}
db.FirstOrInit(&user, map[string]interface{}{"name": "jinzhu"})
//// user -> User{Id: 111, Name: "Jinzhu", Age: 20}
```

### Attrs

Initialize struct with argument if record not found

```go
// Unfound
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrInit(&user)
//// SELECT * FROM USERS WHERE name = 'non_existing' ORDER BY id LIMIT 1;
//// user -> User{Name: "non_existing", Age: 20}

db.Where(User{Name: "non_existing"}).Attrs("age", 20).FirstOrInit(&user)
//// SELECT * FROM USERS WHERE name = 'non_existing' ORDER BY id LIMIT 1;
//// user -> User{Name: "non_existing", Age: 20}

// Found
db.Where(User{Name: "Jinzhu"}).Attrs(User{Age: 30}).FirstOrInit(&user)
//// SELECT * FROM USERS WHERE name = jinzhu' ORDER BY id LIMIT 1;
//// user -> User{Id: 111, Name: "Jinzhu", Age: 20}
```

### Assign

Assign argument to struct regardless it is found or not

```go
// Unfound
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrInit(&user)
//// user -> User{Name: "non_existing", Age: 20}

// Found
db.Where(User{Name: "Jinzhu"}).Assign(User{Age: 30}).FirstOrInit(&user)
//// SELECT * FROM USERS WHERE name = jinzhu' ORDER BY id LIMIT 1;
//// user -> User{Id: 111, Name: "Jinzhu", Age: 30}
```

## FirstOrCreate

Get first matched record, or create a new one with given conditions (only works with struct, map conditions)

```go
// Unfound
db.FirstOrCreate(&user, User{Name: "non_existing"})
//// INSERT INTO "users" (name) VALUES ("non_existing");
//// user -> User{Id: 112, Name: "non_existing"}

// Found
db.Where(User{Name: "Jinzhu"}).FirstOrCreate(&user)
//// user -> User{Id: 111, Name: "Jinzhu"}
```

### Attrs

Assign struct with argument if record not found and create with those values

```go
// Unfound
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrCreate(&user)
//// SELECT * FROM users WHERE name = 'non_existing' ORDER BY id LIMIT 1;
//// INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
//// user -> User{Id: 112, Name: "non_existing", Age: 20}

// Found
db.Where(User{Name: "jinzhu"}).Attrs(User{Age: 30}).FirstOrCreate(&user)
//// SELECT * FROM users WHERE name = 'jinzhu' ORDER BY id LIMIT 1;
//// user -> User{Id: 111, Name: "jinzhu", Age: 20}
```

### Assign

Assign it to the record regardless it is found or not, and save back to database.

```go
// Unfound
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrCreate(&user)
//// SELECT * FROM users WHERE name = 'non_existing' ORDER BY id LIMIT 1;
//// INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
//// user -> User{Id: 112, Name: "non_existing", Age: 20}

// Found
db.Where(User{Name: "jinzhu"}).Assign(User{Age: 30}).FirstOrCreate(&user)
//// SELECT * FROM users WHERE name = 'jinzhu' ORDER BY id LIMIT 1;
//// UPDATE users SET age=30 WHERE id = 111;
//// user -> User{Id: 111, Name: "jinzhu", Age: 30}
```

# first or create

# Optimizer/Index/Comment Hints

# Iteration

# FindInBatches

# Hooks

## Pluck

Query single column from a model as a map, if you want to query multiple columns, you should use [`Scan`](#Scan) instead

```go
var ages []int64
db.Find(&users).Pluck("age", &ages)

var names []string
db.Model(&User{}).Pluck("name", &names)

db.Table("deleted_users").Pluck("name", &names)

// Requesting more than one column? Do it like this:
db.Select("name, age").Find(&users)
```

## Scan

Scan results into another struct.

```go
type Result struct {
  Name string
  Age  int
}

var result Result
db.Table("users").Select("name, age").Where("name = ?", "Antonio").Scan(&result)

// Raw SQL
db.Raw("SELECT name, age FROM users WHERE name = ?", "Antonio").Scan(&result)
```

Unscoped

## Count

Get how many records for a model

```go
db.Where("name = ?", "jinzhu").Or("name = ?", "jinzhu 2").Find(&users).Count(&count)
// SELECT * from USERS WHERE name = 'jinzhu' OR name = 'jinzhu 2'; (users)
// SELECT count(*) FROM users WHERE name = 'jinzhu' OR name = 'jinzhu 2'; (count)

db.Model(&User{}).Where("name = ?", "jinzhu").Count(&count)
// SELECT count(*) FROM users WHERE name = 'jinzhu'; (count)

db.Table("deleted_users").Count(&count)
// SELECT count(*) FROM deleted_users;

db.Table("deleted_users").Select("count(distinct(name))").Count(&count)
// SELECT count( distinct(name) ) FROM deleted_users; (count)
```

**NOTE** When use `Count` in a query chain, it has to be the last one, as it will overwrite `SELECT` columns, But using the `count` keyword does not

Scopes
