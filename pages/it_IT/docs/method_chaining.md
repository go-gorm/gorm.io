---
title: Method Chaining
layout: page
---

GORM's method chaining feature allows for a smooth and fluent style of coding. Here are examples using both the Traditional API and the Generics API:

### Traditional API

```go
db.Where("name = ?", "jinzhu").Where("age = ?", 18).First(&user)
```

### Generics API (>= v1.30.0)

```go
ctx := context.Background()
user, err := gorm.G[User](db).Where("name = ?", "jinzhu").Where("age = ?", 18).First(ctx)
```

Both APIs support method chaining, but the Generics API provides enhanced type safety and returns errors directly from operation methods.

## Method Categories

GORM organizes methods into three primary categories: `Chain Methods`, `Finisher Methods`, and `New Session Methods`. These categories apply to both the Traditional API and the Generics API.

### Chain Methods

Chain methods are used to modify or append `Clauses` to the current `Statement`. Some common chain methods include:

- `Where`
- `Select`
- `Omit`
- `Joins`
- `Scopes`
- `Preload`
- `Raw` (Note: `Raw` cannot be used in conjunction with other chainable methods to build SQL)

For a comprehensive list, visit [GORM Chainable API](https://github.com/go-gorm/gorm/blob/master/chainable_api.go). Also, the [SQL Builder](sql_builder.html) documentation offers more details about `Clauses`.

### Finisher Methods

Finisher methods are immediate, executing registered callbacks that generate and run SQL commands. This category includes methods:

- `Create`
- `First`
- `Find`
- `Take`
- `Save`
- `Update`
- `Delete`
- `Scan`
- `Row`
- `Rows`

For the full list, refer to [GORM Finisher API](https://github.com/go-gorm/gorm/blob/master/finisher_api.go).

### New Session Methods

GORM defines methods like `Session`, `WithContext`, and `Debug` as New Session Methods, which are essential for creating shareable and reusable `*gorm.DB` instances. For more details, see [Session](session.html) documentation.

## Reusability and Safety

### Traditional API

A critical aspect of GORM's Traditional API is understanding when a `*gorm.DB` instance is safe to reuse. Following a `Chain Method` or `Finisher Method`, GORM returns an initialized `*gorm.DB` instance. This instance is not safe for reuse as it may carry over conditions from previous operations, potentially leading to contaminated SQL queries. For example:

### Example of Unsafe Reuse

```go
queryDB := DB.Where("name = ?", "jinzhu")

// First query
queryDB.Where("age > ?", 10).First(&user)
// SQL: SELECT * FROM users WHERE name = "jinzhu" AND age > 10

// Second query with unintended compounded condition
queryDB.Where("age > ?", 20).First(&user2)
// SQL: SELECT * FROM users WHERE name = "jinzhu" AND age > 10 AND age > 20
```

### Example of Safe Reuse

To safely reuse a `*gorm.DB` instance, use a New Session Method:

```go
queryDB := DB.Where("name = ?", "jinzhu").Session(&gorm.Session{})

// First query
queryDB.Where("age > ?", 10).First(&user)
// SQL: SELECT * FROM users WHERE name = "jinzhu" AND age > 10

// Second query, safely isolated
queryDB.Where("age > ?", 20).First(&user2)
// SQL: SELECT * FROM users WHERE name = "jinzhu" AND age > 20
```

In this scenario, using `Session(&gorm.Session{})` ensures that each query starts with a fresh context, preventing the pollution of SQL queries with conditions from previous operations. This is crucial for maintaining the integrity and accuracy of your database interactions.

### Generics API

One of the significant advantages of GORM's Generics API is that it inherently addresses the SQL pollution issue. With the Generics API, you don't need to worry about reusing instances unsafely because:

1. The context is passed directly to each operation method
2. Errors are returned directly from operation methods
3. The generic interface design prevents condition pollution

Here's an example of how the Generics API handles method chaining safely:

```go
ctx := context.Background()

// Define a reusable query base
genericDB := gorm.G[User](db).Where("name = ?", "jinzhu")

// First query
user1, err1 := genericDB.Where("age > ?", 10).First(ctx)
// SQL: SELECT * FROM users WHERE name = "jinzhu" AND age > 10 LIMIT 1

// Second query, no condition pollution
user2, err2 := genericDB.Where("age > ?", 20).First(ctx)
// SQL: SELECT * FROM users WHERE name = "jinzhu" AND age > 20 LIMIT 1
```

The Generics API design significantly reduces the risk of SQL pollution, making your database interactions more reliable and predictable.

## Examples for Clarity

Let's clarify with a few examples using both the Traditional API and the Generics API:

### Traditional API Examples

- **Example 1: Safe Instance Reuse**

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
// 'db' is a newly initialized `*gorm.DB`, which is safe to reuse.

db.Where("name = ?", "jinzhu").Where("age = ?", 18).Find(&users)
// The first `Where("name = ?", "jinzhu")` call is a chain method that initializes a `*gorm.DB` instance, or `*gorm.Statement`.
// The second `Where("age = ?", 18)` call adds a new condition to the existing `*gorm.Statement`.
// `Find(&users)` is a finisher method, executing registered Query Callbacks, generating and running:
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18;

db.Where("name = ?", "jinzhu2").Where("age = ?", 20).Find(&users)
// Here, `Where("name = ?", "jinzhu2")` starts a new chain, creating a fresh `*gorm.Statement`.
// `Where("age = ?", 20)` adds to this new statement.
// `Find(&users)` again finalizes the query, executing and generating:
// SELECT * FROM users WHERE name = 'jinzhu2' AND age = 20;

db.Find(&users)
// Directly calling `Find(&users)` without any `Where` starts a new chain and executes:
// SELECT * FROM users;
```

In this example, each chain of method calls is independent, ensuring clean, non-polluted SQL queries.

- **(Bad) Example 2: Unsafe Instance Reuse**

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
// 'db' is a newly initialized *gorm.DB, safe for initial reuse.

tx := db.Where("name = ?", "jinzhu")
// `Where("name = ?", "jinzhu")` initializes a `*gorm.Statement` instance, which should not be reused across different logical operations.

// Good case
tx.Where("age = ?", 18).Find(&users)
// Reuses 'tx' correctly for a single logical operation, executing:
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18

// Bad case
tx.Where("age = ?", 28).Find(&users)
// Incorrectly reuses 'tx', compounding conditions and leading to a polluted query:
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18 AND age = 28;
```

In this bad example, reusing the `tx` variable leads to compounded conditions, which is generally not desirable.

- **Example 3: Safe Reuse with New Session Methods**

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
// 'db' is a newly initialized *gorm.DB, safe to reuse.

tx := db.Where("name = ?", "jinzhu").Session(&gorm.Session{})
tx := db.Where("name = ?", "jinzhu").WithContext(context.Background())
tx := db.Where("name = ?", "jinzhu").Debug()
// `Session`, `WithContext`, `Debug` methods return a `*gorm.DB` instance marked as safe for reuse. They base a newly initialized `*gorm.Statement` on the current conditions.

// Good case
tx.Where("age = ?", 18).Find(&users)
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18

// Good case
tx.Where("age = ?", 28).Find(&users)
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 28;
```

In this example, using New Session Methods `Session`, `WithContext`, `Debug` correctly initializes a `*gorm.DB` instance for each logical operation, preventing condition pollution and ensuring each query is distinct and based on the specific conditions provided.

### Generics API Examples

- **Example 4: Method Chaining with Generics API**

```go
ctx := context.Background()

// Initialize a generic DB instance
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})

// Chain methods with type safety
user, err := gorm.G[User](db).Where("name = ?", "jinzhu").Where("age = ?", 18).First(ctx)
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18 LIMIT 1;

// Reuse the generic DB instance safely
genericDB := gorm.G[User](db).Where("name = ?", "jinzhu")

// Multiple operations with the same base conditions
user1, err1 := genericDB.Where("age = ?", 18).First(ctx)
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18 LIMIT 1;

users, err2 := genericDB.Where("age > ?", 20).Find(ctx)
// SELECT * FROM users WHERE name = 'jinzhu' AND age > 20;

// Raw SQL with type safety
users, err3 := gorm.G[User](db).Raw("SELECT * FROM users WHERE name = ? AND age > ?", "jinzhu", 18).Find(ctx)
```

In this example, the Generics API provides type safety while maintaining the fluent method chaining style. The context is passed directly to the finisher methods (`First`, `Find`), and errors are returned directly from these methods, following Go's standard error handling pattern.

Overall, these examples illustrate the importance of understanding GORM's behavior with respect to method chaining and instance management to ensure accurate and efficient database querying. The Generics API offers a more type-safe and less error-prone approach to method chaining compared to the Traditional API.
