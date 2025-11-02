---
title: Query Templates
layout: page
---

# Template-Driven Query Interfaces

Define Go interfaces with SQL template comments to generate concrete, type-safe query methods. Parameters bind automatically, and any method missing a `context.Context` parameter receives one in the generated implementation.

```go
type Query[T any] interface {
  // SELECT * FROM @@table WHERE id=@id
  GetByID(id int) (T, error)

  // SELECT * FROM @@table WHERE @@column=@value
  FilterWithColumn(column string, value string) (T, error)

  // SELECT * FROM @@table
  // {{where}}
  //   {{if user.Name }} name=@user.Name {{end}}
  //   {{if user.Age > 0}} AND age=@user.Age {{end}}
  // {{end}}
  SearchUsers(user User) ([]T, error)

  // UPDATE @@table
  // {{set}}
  //   {{if user.Name != ""}} name=@user.Name, {{end}}
  //   {{if user.Age > 0}} age=@user.Age, {{end}}
  //   {{if user.Age >= 18}} is_adult=1 {{else}} is_adult=0 {{end}}
  // {{end}}
  // WHERE id=@id
  UpdateUser(user User, id int) error
}
```

## Usage Examples

```go
// SQL: SELECT * FROM users WHERE id=123
user, err := generated.Query[User](db).GetByID(ctx, 123)

// SQL: SELECT * FROM users WHERE name="jinzhu" AND age=25 (appended to current builder)
users, err := generated.Query[User](db).FilterByNameAndAge("jinzhu", 25).Find(ctx)

// SQL: UPDATE users SET name="jinzhu", age=20, is_adult=1 WHERE id=1
err := generated.Query[User](db).UpdateUser(ctx, User{Name: "jinzhu", Age: 20}, 1)
```

## Template DSL

| Directive   | Purpose                          | Example                                  |
| ----------- | -------------------------------- | ---------------------------------------- |
| `@@table`   | Model table name                 | `SELECT * FROM @@table WHERE id=@id`     |
| `@@column`  | Dynamic column binding           | `@@column=@value`                        |
| `@param`    | Bind Go params to SQL params     | `WHERE name=@user.Name`                  |
| `{{where}}` | Conditional WHERE wrapper        | `{{where}} age > 18 {{end}}`             |
| `{{set}}`   | Conditional SET wrapper (UPDATE) | `{{set}} name=@name {{end}}`             |
| `{{if}}`    | Conditional SQL fragment         | `{{if age > 0}} AND age=@age {{end}}`    |
| `{{for}}`   | Iterate over a collection        | `{{for _, t := range tags}} ... {{end}}` |

### SQL Snippets

```sql
-- Safe parameter binding
SELECT * FROM @@table WHERE id=@id AND status=@status

-- Dynamic column binding
SELECT * FROM @@table WHERE @@column=@value

-- Conditional WHERE
SELECT * FROM @@table
{{where}}
  {{if name != ""}} name=@name {{end}}
  {{if age > 0}} AND age=@age {{end}}
{{end}}

-- Dynamic UPDATE
UPDATE @@table
{{set}}
  {{if user.Name != ""}} name=@user.Name, {{end}}
  {{if user.Email != ""}} email=@user.Email {{end}}
{{end}}
WHERE id=@id

-- Iteration
SELECT * FROM @@table
{{where}}
  {{for _, tag := range tags}}
    {{if tag != ""}} tags LIKE concat('%',@tag,'%') OR {{end}}
  {{end}}
{{end}}
```

Next, configure output paths or custom helpers with the [generation configuration guide](configuration.html), or revisit the [CLI overview](index.html).
