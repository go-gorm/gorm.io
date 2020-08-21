---
title: Method Chaining
layout: page
---

GORM allows method chaining, so you can write code like this:

```go
First(&user)
}

tx := db. Where("name = ?", "jinzhu")
// NOT Safe as reusing Statement
for i := 0; i < 100; i++ {
  go tx.
```

There are three kinds of methods in GORM: `Chain Method`, `Finisher Method`, `New Session Method`

## Chain Method

Chain methods are methods to modify or add `Clauses` to current `Statement`, like:

`Where`, `Select`, `Omit`, `Joins`, `Scopes`, `Preload`, `Raw`...

Here is [the full lists](https://github.com/go-gorm/gorm/blob/master/chainable_api.go), also check out the [SQL Builder](sql_builder.html) for more details about `Clauses`

## Finisher Method

Finishers are immediate methods that execute registered callbacks, which will generate and execute SQL, like those methods:

`Create`, `First`, `Find`, `Take`, `Save`, `Update`, `Delete`, `Scan`, `Row`, `Rows`...

Check out [the full lists](https://github.com/go-gorm/gorm/blob/master/finisher_api.go) here

## New Session Mode

After new initialized `*gorm.DB` or a `New Session Method`, following methods call will create a new `Statement` instance instead of using the current one

GROM defined `Session`, `WithContext`, `Debug` methods as `New Session Method`, refer [Session](session.html) for more details

Let explain it with examples:

Example 1:

```go
db, err := gorm. Open(sqlite. Open("test.db"), &gorm. Config{})

// Safe for new initialized *gorm.DB
for i := 0; i < 100; i++ {
  go db. First(&user)
}

tx := db. Where("name = ?", "jinzhu")
// NOT Safe as reusing Statement
for i := 0; i < 100; i++ {
  go tx. First(&user) // `name = 'jinzhu'` will applies to all
}

tx := db. Session(&gorm. Session{WithConditions: true})
// Safe after a `New Session Method`
for i := 0; i < 100; i++ {
  go tx. First(&user) // `name = 'jinzhu'` will applies to all
}
```

Example 2:

```go
db, err := gorm. Open(sqlite. Open("test.db"), &gorm. Config{})

// Safe for new initialized *gorm.DB
for i := 0; i < 100; i++ {
  go db. First(&user)
}

tx := db. Where("name = ?", "jinzhu")
// NOT Safe as reusing Statement
for i := 0; i < 100; i++ {
  go tx. First(&user) // `name = 'jinzhu'` will applies to all
}

tx := db. Session(&gorm. Session{WithConditions: true})
// Safe after a `New Session Method`
for i := 0; i < 100; i++ {
  go tx. First(&user) // `name = 'jinzhu'` will applies to all
}
```

**NOTE** In example 2, the first query affected the second generated SQL as GORM reused the `Statement`, this might cause unexpected issues, refer [Goroutine Safety](#goroutine_safe) for how to avoid it

## <span id="goroutine_safe">Method Chain Safety/Goroutine Safety</span>

Methods will create new `Statement` instances for new initialized `*gorm.DB` or after a `New Session Method`, so to reuse a `*gorm.DB`, you need to make sure they are under `New Session Mode`, for example:

```go
db, err := gorm. Open(sqlite. Open("test.db"), &gorm. Config{})

// Safe for new initialized *gorm.DB
for i := 0; i < 100; i++ {
  go db. First(&user)
}

tx := db. Where("name = ?", "jinzhu")
// NOT Safe as reusing Statement
for i := 0; i < 100; i++ {
  go tx. First(&user) // `name = 'jinzhu'` will applies to all
}

tx := db. Session(&gorm. Session{WithConditions: true})
// Safe after a `New Session Method`
for i := 0; i < 100; i++ {
  go tx. First(&user) // `name = 'jinzhu'` will applies to all
}
```
