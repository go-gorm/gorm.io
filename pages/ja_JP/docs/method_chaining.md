---
title: メソッドのチェーン
layout: page
---

GORMのメソッドチェーン機能は、円滑で流暢なコーディングスタイルを可能にします。 Here are examples using both the Traditional API and the Generics API:

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

## メソッドのカテゴリ

GORMにおいて、メソッドはおもに `Chain Methods`、 `Finisher Methods`、 `New Session Methods` の3つのカテゴリに分類されます。 These categories apply to both the Traditional API and the Generics API.

### Chain Methods

Chain Method は、現在の `Statement` に `Clauses`の変更または追加を行うために使用されます。 一般的なチェーンメソッドには以下のものがあります。

- `Where`
- `Select`
- `Omit`
- `Joins`
- `Scopes`
- `Preload`
- `Raw` (注意: `Raw` は、SQLを構築する他のチェーン可能なメソッドと組み合わせて使用することはできません)

包括的なリストについては [GORM Chainable API](https://github.com/go-gorm/gorm/blob/master/chainable_api.go) をご覧ください。 また、 [SQL Builder](sql_builder.html) のドキュメントでは `Clauses` についての詳細が示されています。

### Finisher Methods

Finisher Method が現れると、それまでに登録されたコールバックが即実行され、SQLコマンドを生成、実行します。 このカテゴリには以下のメソッドが含まれます。

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

一覧については [GORM Finisher API](https://github.com/go-gorm/gorm/blob/master/finisher_api.go) を参照してください。

### New Session Methods

`Session`、`WithContext`、`Debug` といったメソッドは New Session Methods として定義されており、共有可能かつ再利用可能な `*gorm.DB` インスタンスを生み出すのに必要不可欠です。 詳細は [セッション](session.html) のドキュメントを参照してください。

## 再利用性と安全性

### Traditional API

A critical aspect of GORM's Traditional API is understanding when a `*gorm.DB` instance is safe to reuse. `Chain Method` または `Finisher Method` の後ろに続けて置くことで、GORMは `*gorm.DB` インスタンスを初期化して返します。 このインスタンスは以前の操作から条件を引き継いでおり、SQLクエリの汚染につながる可能性があるため、安全に再利用することはできません。 例:

### 安全でない再利用の例

```go
queryDB := DB.Where("name = ?", "jinzhu")

// First query
queryDB.Where("age > ?", 10).First(&user)
// SQL: SELECT * FROM users WHERE name = "jinzhu" AND age > 10

// Second query with unintended compounded condition
queryDB.Where("age > ?", 20).First(&user2)
// SQL: SELECT * FROM users WHERE name = "jinzhu" AND age > 10 AND age > 20
```

### 安全な再利用の例

`*gorm.DB` インスタンスを安全に再利用するには、New Session Method を使用します。

```go
queryDB := DB.Where("name = ?", "jinzhu").Session(&gorm.Session{})

// First query
queryDB.Where("age > ?", 10).First(&user)
// SQL: SELECT * FROM users WHERE name = "jinzhu" AND age > 10

// Second query, safely isolated
queryDB.Where("age > ?", 20).First(&user2)
// SQL: SELECT * FROM users WHERE name = "jinzhu" AND age > 20
```

このシナリオでは `Session(&gorm.Session{})` を使用することで、直前の操作がもたらす条件によってSQLクエリが汚染されることを防止し、毎クエリが新鮮なコンテキストから始動することを確実なものにしています。 これは、データベースとのやりとりの整合性と正確性を維持するために重要です。

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

## わかりやすい例

Let's clarify with a few examples using both the Traditional API and the Generics API:

### Traditional API Examples

- **例1: インスタンスの安全な再利用**

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

この例では、メソッド呼び出しの各チェーンは独立しており、すべてのSQLクエリがクリーンかつ汚染されていないことを確実にします。

- **例2 (悪い例): 安全でないインスタンスの再利用**

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

これは `tx` 変数の再利用によって条件が混ざってしまった悪い例です。一般的には望ましくありません。

- **例3: New Session Methods による安全な再利用**

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

この例では、New Session Methods である `Session`、`WithContext`、`Debug` を使用することで、論理操作ごとに `*gorm.DB` インスタンスが正しい形で初期化されています。これによって条件は汚染されることなく、各クエリが与えられた固有の条件に基づいて独立していることを確実なものにしています。

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

以上の例で、正確で効率的なデータベース操作を確立するために、メソッドチェーンとインスタンス管理に関するGORMの動作を理解することの重要性が一般に示されました。 The Generics API offers a more type-safe and less error-prone approach to method chaining compared to the Traditional API.
