---
title: Generation Configuration
layout: page
---

# Generation Configuration

You can run `gorm gen` with zero configuration, but declaring a package-level `genconfig.Config` lets you control output paths, type mappings, and inclusion rules.

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

## JSON Field Mapping Example

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

Return to [template queries](query_templates.html) or the [CLI overview](index.html).
