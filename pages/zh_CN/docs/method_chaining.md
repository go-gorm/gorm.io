---
title: 链式方法
layout: page
---

GORM 的链式方法特性可让编码更加流畅自然。 这里有一个例子：

```go
db.Where("name = ?", "jinzhu").Where("age = ?", 18).First(&user)
```

## 方法分类

GORM 将方法分为三大类： `Chain Methods`, `Finisher Methods`, and `New Session Methods`.

### 链式方法

用于修改或追加目前 `Clauses` 的 `Statement`。 一些常见的链式方法包括：

- ``
- `Select`
- `Omit`
- `Joins`
- `Scopes`
- `Preload`
- `Raw` (提示：`Raw` 不能与其他链式方法结合使用来构建 SQL）

完整列表，访问 [GORM Chainable API](https://github.com/go-gorm/gorm/blob/master/chainable_api.go)。 另外， [SQL Builder](sql_builder.html) 文档提供了更多关于 `Clauses` 的详细信息。

### Finisher 方法

终结方法是即时的，执行生成和运行 SQL 命令的注册回调。 此类别包括方法：

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

完整列表, 参考 [GORM Finisher API](https://github.com/go-gorm/gorm/blob/master/finisher_api.go)。

### 新的Session方法

GORM 将 `Session`、`WithContext` 和 `Debug` 等方法定义为“新会话方法”，它们对于创建可共享和可复用的 `*gorm.DB` 实例非常重要。 更多详情，请参阅 [Session](session.html) 文档。

## 可复用性与安全性

GORM 的一个关键方面是要弄清楚什么时候可以安全地重复使用 `*gorm.DB` 实例。 在调用 链式方法`Chain Method` 或 终结方法`Finisher Method` 之后，GORM 会返回一个已初始化的 `*gorm.DB` 实例。 这个实例无法安全地重新使用，因为它可能会将先前操作中的状况带回，有可能导致被污染的 SQL 查询。 例如

### 不安全地复用的例子

```go
queryDB := DB.Where("name = ?", "jinzhu")

// First query
queryDB.Where("age > ?", 10).First(&user)
// SQL: SELECT * FROM users WHERE name = "jinzhu" AND age > 10

// Second query with unintended compounded condition
queryDB.Where("age > ?", 20).First(&user2)
// SQL: SELECT * FROM users WHERE name = "jinzhu" AND age > 10 AND age > 20
```

### 安全再利用的例子

安全地复用 `*gorm.DB` 实例，通过使用新会话方法：

```go
queryDB := DB.Where("name = ?", "jinzhu").Session(&gorm.Session{})

// First query
queryDB.Where("age > ?", 10).First(&user)
// SQL: SELECT * FROM users WHERE name = "jinzhu" AND age > 10

// Second query, safely isolated
queryDB.Where("age > ?", 20).First(&user2)
// SQL: SELECT * FROM users WHERE name = "jinzhu" AND age > 20
```

在这种情况下，使用 `Session(gorm.Session{})` 可以确保每次查询都从全新的上下文开始，避免前一次操作&的条件污染后续 SQL 查询。 这对于维护数据库操作的完整性和准确性至关重要。

## 清晰示例

让我们通过几个例子来解释一下：

- **例子1：安全复用实例**

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
// 'db' is a newly initialized `*gorm.DB`, which is safe to reuse.

db.where ("name = ?", "jinzhu").Where("age = ?", 18).Find(&users)
// 第一个`Where ("name = ?", "jinzhu")`是一个启动一个 `*gorm.DB` 实例或`*gorm.Statement`的链式方法。
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

在这个例子中，每个方法调用链都是独立的，确保干净、无污染的 SQL 查询。

- **(Bad) 示例2：不安全的实例复用**

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

- **例3：使用新会话方法安全复用**

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

在这个例子中，使用新会话方法 `Session`, `WithContext`, `Debug` 为每个逻辑操作正确地初始化一个 `*gorm.DB`实例，从而防止了条件污染，确保每个查询都是独立的，并且基于所提供的特定条件。

Overall, these examples illustrate the importance of understanding GORM's behavior with respect to method chaining and instance management to ensure accurate and efficient database querying.
