---
title: GORM CLI
layout: page
---

GORM CLI generates two complementary layers of code for your GORM projects:

* **Type-safe, interface-driven query APIs** — from Go interfaces with powerful SQL templates
* **Model-based field helpers** — from your model structs for filters, updates, ordering, and associations

Together they deliver **compile-time safety** and a fluent, discoverable API for all database operations

## Key Features

* **Strong Type Safety (default)** — Compile-time guarantees with Go generics.
* **Interface-Driven Query Generation** — Define Go interfaces with SQL template comments to produce concrete, type-safe methods.
* **Model-Based Field Helpers** — Generate helpers from model structs for filtering, ordering, updates, and association handling.
* **Seamless GORM Integration** — Works natively with `gorm.io/gorm`—no runtime magic, just plain Go.
* **Flexible Configuration** — Customize output paths, include/exclude rules, and field mappings via `genconfig.Config`.
* **Rich Association Operations** — Strongly-typed `Create`, `CreateInBatch`, `Update`, `Unlink`, and `Delete` for associations.

## 🚀 Quick Start

### 1) Install

```bash
go install gorm.io/cli/gorm@latest
```

### 2) Define Models & a Query Interface

```go
// examples/models/user.go
type User struct {
  gorm.Model
  Name string
  Age  int
  Pets []Pet `gorm:"many2many:user_pets"`
}

type Pet struct {
  gorm.Model
  Name string
}

// examples/query.go
type Query[T any] interface {
  // SELECT * FROM @@table WHERE id=@id
  GetByID(id int) (T, error)
}
```

### 3) Generate & Use

```bash
# Default: strictly typed generics API
gorm gen -i ./examples -o ./generated

# Standard API (still generics-based, relaxed typing for more flexibility)
gorm gen -i ./examples -o ./generated --typed=false
```

```go
// Type-safe query
// SELECT * FROM users WHERE id=123
u, err := generated.Query[User](db).GetByID(ctx, 123)

// Field helpers
// SELECT * FROM users WHERE age>18
users, _ := gorm.G[User](db).Where(generated.User.Age.Gt(18)).Find(ctx)

// Association helpers: create a user with a pet
gorm.G[User](db).
  Set(
    generated.User.Name.Set("alice"),
    generated.User.Pets.Create(generated.Pet.Name.Set("fido")),
  ).
  Create(ctx)
```

---

## Two Generators, One Workflow

GORM CLI uses **two generators that work together**:

### 1) Query API generator

Define methods with **SQL template comments** in Go interfaces to produce concrete, type-safe methods.

### 2) Field helper generator

Generate strongly-typed helpers from your model structs for filters, updates, ordering, and associations without raw SQL.

The generators can be used independently, but they shine when combined—field helpers build expressive builders, and query interfaces capture bespoke SQL. You can start with one and add the other later.

Learn more:

* [Field helpers and associations](field_helpers.html)
* [Template-driven query interfaces](query_templates.html)
* [Configuration and customization](configuration.html)

---

## Next Steps

Keep exploring:

* [Browse field helper patterns](field_helpers.html) for predicates, updates, and association operations.
* [Dive into the query template DSL](query_templates.html) to build typed query methods.
* [Tune generation output](configuration.html) with `genconfig.Config`, custom field mappings, and JSON helpers.
