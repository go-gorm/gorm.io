---
title: Field Helpers
layout: page
---

# Field Helpers

The CLI generates field helpers from your model structs. Use them for typed filters, updates, ordering, and association work without hand-writing SQL strings. They plug into `gorm.G[T]` builders in both the default generics output and the `--typed=false` mode.

## Supported Models & Types

* **Core Go types**: integers, floats, `string`, `bool`, `time.Time`, `[]byte`
* **Named or custom types** implementing `database/sql.Scanner` / `driver.Valuer`
* **Serializer-backed fields** using GORM's `Serializer` interfaces
* **Associations**: `has one` *(including polymorphic)*, `has many` *(including polymorphic)*, `belongs to`, `many2many`

## Predicates & Updates

```go
// Predicates
generated.User.ID.Eq(1)               // id = 1
generated.User.Name.Like("%jinzhu%")  // name LIKE '%jinzhu%'
generated.User.Age.Between(18, 65)    // age BETWEEN 18 AND 65
generated.User.Score.IsNull()         // score IS NULL (e.g., sql.NullInt64)

// Updates (supports expressions and zero-values)
gorm.G[User](db).
  Where(generated.User.Name.Eq("alice")).
  Set(
    generated.User.Name.Set("jinzhu"),
    generated.User.IsAdult.Set(false),
    generated.User.Score.Set(sql.NullInt64{}),
    generated.User.Count.Incr(1),
    generated.User.Age.SetExpr(clause.Expr{
      SQL:  "GREATEST(?, ?)",
      Vars: []any{clause.Column{Name: "age"}, 18},
    }),
  ).
  Update(ctx)

// Create with Set(...)
gorm.G[User](db).
  Set(
    generated.User.Name.Set("alice"),
    generated.User.Age.Set(0),
    generated.User.Status.Set("active"),
  ).
  Create(ctx)
```

> **Standard API note (`--typed=false`)**
> The default output is strictly typed. With the Standard API, you keep generics but can mix raw conditions with helpers:
>
> ```go
> generated.Query[User](db).
>   Where("name = ?", "jinzhu").
>   Where(generated.User.Age.Gt(18)).
>   Find(ctx)
> ```

## Association Operations

Association helpers surface on generated structs as `field.Struct[T]` or `field.Slice[T]` (for example, `generated.User.Pets`, `generated.User.Account`). Combine them inside `Set(...).Create(ctx)` or `Set(...).Update(ctx)` calls.

Supported operations:

* **Create** — create & link a related row per parent
* **CreateInBatch** — batch create/link from a slice
* **Update** — update related rows (with optional conditions)
* **Unlink** — remove only the relationship (clear FK or delete join rows)
* **Delete** — delete related rows (m2m: deletes join rows only)

```go
// Create a pet for each matched user
gorm.G[User](db).
  Where(generated.User.ID.Eq(1)).
  Set(generated.User.Pets.Create(generated.Pet.Name.Set("fido"))).
  Update(ctx)

// Filter on the child before acting
gorm.G[User](db).
  Where(generated.User.ID.Eq(1)).
  Set(generated.User.Pets.Where(generated.Pet.Name.Eq("old")).Delete()).
  Update(ctx)

// Batch link two pets to an existing user
gorm.G[User](db).
  Where(generated.User.ID.Eq(1)).
  Set(generated.User.Pets.CreateInBatch([]models.Pet{{Name: "rex"}, {Name: "spot"}})).
  Update(ctx)
```

Association semantics:

* **Belongs To** — `Unlink` clears the parent FK; `Delete` removes associated rows
* **Has One / Has Many** *(including polymorphic)* — `Unlink` clears the child FK; `Delete` removes child rows
* **Many2Many** — `Unlink`/`Delete` remove join rows only (both sides remain)

Parent operation semantics:

* `Create(ctx)` inserts new parent rows using your `Set(...)` values, then applies association operations
* `Update(ctx)` updates matched parent rows, then applies association operations

Next: learn the [Typed Raw SQL](sql_templates.html) flow or jump back to the [CLI overview](index.html).
