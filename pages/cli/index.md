---
title: GORM CLI
layout: page
---

# GORM CLI Overview

GORM CLI reads the interfaces and structs in your project, turns raw SQL comments into typed query methods, and generates helpers for common model operations. Everything compiles to plain Go that works with `gorm.io/gorm`.

## What you get

* **Generics-first output** with an opt-out flag (`--typed=false`).
* **Typed query methods** generated from SQL comments on interfaces.
* **Field helpers** from models for predicates, updates, and associations.
* **Plain Go code** with no runtime wrappers.

## Where to look next

Two code paths are produced in the same package. Use configuration to choose which interfaces and models are included.

* [Workflow & configuration](workflow.html)
* [Field helpers & associations](field_helpers.html)
* [Typed Raw SQL](sql_templates.html)

## Quick start

1. Install the CLI.

   ```bash
   go install gorm.io/cli/gorm@latest
   ```

2. Define interfaces and models.

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

3. Generate code.

   ```bash
   # Generics output (default)
   gorm gen -i ./examples -o ./generated

   # Relaxed typing
   gorm gen -i ./examples -o ./generated --typed=false
   ```

4. Call the generated APIs.

   ```go
   // Typed raw SQL
   u, err := generated.Query[User](db).GetByID(ctx, 123)

   // Field helpers
   users, _ := gorm.G[User](db).
     Where(generated.User.Age.Gt(18)).
     Find(ctx)

   // Association helpers
   gorm.G[User](db).
     Set(
       generated.User.Name.Set("alice"),
       generated.User.Pets.Create(generated.Pet.Name.Set("fido")),
     ).
     Create(ctx)
   ```

## Configuration

[`genconfig.Config`](workflow.html#configuration-basics) lets you set output paths, choose the interfaces or models to include, and map custom helpers.
