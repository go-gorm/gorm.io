---
title: Workflow & Configuration
layout: page
---

# Workflow & Configuration

`gorm gen` always produces two sets of code. They live in the same package, so you can keep interface-driven queries and model-based helpers side by side.

## Query API generator

Give the CLI an interface and annotate the methods with SQL template comments. The generator expands those comments, binds parameters, and adds a `context.Context` parameter when it is missing.

* Works with the default generics output or the `--typed=false` flag.
* Keeps SQL next to the interface that describes it.
* Emits plain Go implementations with no reflection.

## Field helper generator

Point the CLI at your model structs. The generator scans fields and relationships to build helper types.

* Predicate builders like `generated.User.Name.Eq("alice")`.
* Update helpers for `Set`, `SetExpr`, `Incr`, and related calls.
* Association helpers for `Create`, `CreateInBatch`, `Update`, `Unlink`, and `Delete`.

## Typical command

```bash
gorm gen -i ./internal/models -o ./internal/generated
```

## Configuration basics

`gorm gen` works without configuration, but a package-level `genconfig.Config` lets you pick output paths, decide which interfaces or structs are included, and map custom helper types.

```go
package examples

import (
  "database/sql"
  "gorm.io/cli/gorm/field"
  "gorm.io/cli/gorm/genconfig"
)

var _ = genconfig.Config{
  OutPath: "examples/output",

  // Map Go types to helper kinds
  FieldTypeMap: map[any]any{
    sql.NullTime{}: field.Time{},
  },

  // Map `gen:"name"` tags to helper kinds
  FieldNameMap: map[string]any{
    "json": JSON{}, // use a custom JSON helper where fields are tagged `gen:"json"`
  },

  // Narrow what gets generated (patterns or type literals)
  IncludeInterfaces: []any{"Query*", models.Query(nil)},
  IncludeStructs:    []any{"User", "Account*", models.User{}},
}
```

Adjust the `OutPath` to pick a target package and use the include lists to focus on the interfaces and structs you want the CLI to read.

### JSON field mapping example

0) Declare configuration

```go
package examples

import "gorm.io/cli/gorm/genconfig"

var _ = genconfig.Config{
  OutPath: "examples/output",
  FieldNameMap: map[string]any{
    "json": JSON{}, // map fields with `gen:"json"` to a custom helper
  },
}
```

1) Tag the model field

```go
package models

type User struct {
  // ...
  Profile string `gen:"json"`
}
```

2) Define the helper

```go
// JSON is a field helper for JSON columns that generates different SQL per dialect.
type JSON struct{ column clause.Column }

func (j JSON) WithColumn(name string) JSON {
  c := j.column
  c.Name = name
  return JSON{column: c}
}

func (j JSON) Equal(path string, value any) clause.Expression {
  return jsonEqualExpr{col: j.column, path: path, val: value}
}

type jsonEqualExpr struct {
  col  clause.Column
  path string
  val  any
}

func (e jsonEqualExpr) Build(builder clause.Builder) {
  if stmt, ok := builder.(*gorm.Statement); ok {
    switch stmt.Dialector.Name() {
    case "mysql":
      v, _ := json.Marshal(e.val)
      clause.Expr{SQL: "JSON_EXTRACT(?, ?) = CAST(? AS JSON)", Vars: []any{e.col, e.path, string(v)}}.Build(builder)
    case "sqlite":
      clause.Expr{SQL: "json_valid(?) AND json_extract(?, ?) = ?", Vars: []any{e.col, e.col, e.path, e.val}}.Build(builder)
    default:
      clause.Expr{SQL: "jsonb_extract_path_text(?, ?) = ?", Vars: []any{e.col, e.path[2:], e.val}}.Build(builder)
    }
  }
}
```

3) Use it in queries

```go
// Generates dialect-specific JSON comparisons
got, err := gorm.G[models.User](db).
  Where(generated.User.Profile.Equal("$.vip", true)).
  Take(ctx)
```

Re-run `gorm gen` whenever you add new interfaces or structs or adjust configuration; only the affected output files change.
