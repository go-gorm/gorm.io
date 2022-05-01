---
title: Цепочки методов
layout: страница
---

GORM позволяет делать цепочки методов, так что вы можете написать код следующим образом:

```go
db.Where("name = ?", "jinzhu").Where("age = ?", 18).First(&user)
```

There are three kinds of methods in GORM: `Chain Method`, `Finisher Method`, `New Session Method`.

After a `Chain method`, `Finisher Method`, GORM returns an initialized `*gorm.DB` instance, which is NOT safe to reuse anymore, or new generated SQL might be polluted by the previous conditions, for example:

```go
queryDB := DB.Where("name = ?", "jinzhu")

queryDB.First(&user)
// SELECT * FROM users WHERE name = "jinzhu"

queryDB.Where("name = ?", "jinzhu2").First(&user2)
// SELECT * FROM users WHERE name = "jinzhu" AND name = "jinzhu2"
```

In order to reuse a initialized `*gorm.DB` instance, you can use a `New Session Method` to create a shareable `*gorm.DB`, e.g:

```go
queryDB := DB.Where("name = ?", "jinzhu").Session(&gorm.Session{})

queryDB.First(&user)
// SELECT * FROM users WHERE name = "jinzhu"

queryDB.Where("name = ?", "jinzhu2").First(&user2)
// SELECT * FROM users WHERE name = "jinzhu2"
```

## Метод цепочки

Chain methods are methods to modify or add `Clauses` to current `Statement`, like:

`Where`, `Select`, `Omit`, `Joins`, `Scopes`, `Preload`, `Raw` (`Raw` can't be used with other chainable methods to build SQL)...

Here is [the full lists](https://github.com/go-gorm/gorm/blob/master/chainable_api.go), also check out the [SQL Builder](sql_builder.html) for more details about `Clauses`.

## <span id="finisher_method">Finisher Method</span>

Finishers are immediate methods that execute registered callbacks, which will generate and execute SQL, like those methods:

`Create`, `First`, `Find`, `Take`, `Save`, `Update`, `Delete`, `Scan`, `Row`, `Rows`...

Check out [the full lists](https://github.com/go-gorm/gorm/blob/master/finisher_api.go) here.

## <span id="goroutine_safe">New Session Method</span>

GORM defined `Session`, `WithContext`, `Debug` methods as `New Session Method`, refer [Session](session.html) for more details.

After a `Chain method`, `Finisher Method`, GORM returns an initialized `*gorm.DB` instance, which is NOT safe to reuse anymore, you should use a `New Session Method` to mark the `*gorm.DB` as shareable.

Let's explain it with examples:

Example 1:

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
// db is a new initialized `*gorm.DB`, which is safe to reuse

db.Where("name = ?", "jinzhu").Where("age = ?", 18).Find(&users)
// `Where("name = ?", "jinzhu")` is the first chain method call, it will create an initialized `*gorm.DB` instance, aka `*gorm.Statement`
// `Where("age = ?", 18)` is the second chain method call, it reuses the above `*gorm.Statement`, adds new condition `age = 18` to it
// `Find(&users)` is a finisher method, it executes registered Query Callbacks, which generates and runs the following SQL:
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18;

db.Where("name = ?", "jinzhu2").Where("age = ?", 20).Find(&users)
// `Where("name = ?", "jinzhu2")` is also the first chain method call, it creates a new `*gorm.Statement`
// `Where("age = ?", 20)` reuses the above `Statement`, and add conditions to it
// `Find(&users)` is a finisher method, it executes registered Query Callbacks, generates and runs the following SQL:
// SELECT * FROM users WHERE name = 'jinzhu2' AND age = 20;

db.Find(&users)
// `Find(&users)` is a finisher method call, it also creates a new `Statement` and executes registered Query Callbacks, generates and runs the following SQL:
// SELECT * FROM users;
```

(Bad) Example 2:

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
// db is a new initialized *gorm.DB, which is safe to reuse

tx := db.Where("name = ?", "jinzhu")
// `Where("name = ?", "jinzhu")` returns an initialized `*gorm.Statement` instance after chain method `Where`, which is NOT safe to reuse

// good case
tx.Where("age = ?", 18).Find(&users)
// `tx.Where("age = ?", 18)` use the above `*gorm.Statement`, adds new condition to it
// `Find(&users)` is a finisher method call, it executes registered Query Callbacks, generates and runs the following SQL:
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18

// bad case
tx.Where("age = ?", 28).Find(&users)
// `tx.Where("age = ?", 18)` also use the above `*gorm.Statement`, and keep adding conditions to it
// So the following generated SQL is polluted by the previous conditions:
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18 AND age = 28;
```

Example 3:

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
// db is a new initialized *gorm.DB, which is safe to reuse

tx := db.Where("name = ?", "jinzhu").Session(&gorm.Session{})
tx := db.Where("name = ?", "jinzhu").WithContext(context.Background())
tx := db.Where("name = ?", "jinzhu").Debug()
// `Session`, `WithContext`, `Debug` returns `*gorm.DB` marked as safe to reuse, newly initialized `*gorm.Statement` based on it keeps current conditions

// good case
tx.Where("age = ?", 18).Find(&users)
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18

// good case
tx.Where("age = ?", 28).Find(&users)
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 28;
```
