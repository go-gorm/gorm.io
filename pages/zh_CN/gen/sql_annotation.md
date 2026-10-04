---
title: Annotation Syntax
layout: page
---

在接口的方法上的注释，Gen将解析它们并为应用的结构生成查询 API。

Gen provides some conventions for dynamic conditionally SQL support, let us introduce them from three aspects:

* 返回结果
* 模板占位符
* 模板表达式

## 返回结果

Gen allows to configure returning result type. Basic types:

| Option             | Description                                                                                   |
| ------------------ | --------------------------------------------------------------------------------------------- |
| `gen.T`            | returns the applied model struct (value)                                                      |
| `gen.M`            | returns `map[string]interface{}`                                                              |
| `gen.RowsAffected` | returns rows affected from the database (type: `int64`); makes the method execute with `Exec` |
| `error`            | returns error if any                                                                          |
| `gen.SQLResult`    | returns `sql.Result` from a direct `ExecContext` call                                         |
| `gen.SQLRow`       | returns `*sql.Row` (single row from a raw query)                                              |
| `gen.SQLRows`      | returns `*sql.Rows` (row cursor from a raw query)                                             |

`gen.SQLResult`/`gen.SQLRow`/`gen.SQLRows` are **generation markers**, not Go type aliases you can assign through: in the interface you may write either the marker or the standard-library spelling (`sql.Result`, `*sql.Row`, `*sql.Rows` with `database/sql` imported) — the generator recognizes both and emits the standard-library type in the generated method signature.

Rules enforced at generation time:

* at most **one** data value and at most **one** `error` in the result list (`query method cannot return more than 1 ... value`);
* a result of `interface{}` (or `any`) is rejected;
* a struct from the `main` package cannot be returned;
* omitting `error` is allowed — the generated method then discards it.

e.g:

```go
type Querier interface {
  // SELECT * FROM @@table WHERE id=@id
  GetByID(id int) (gen.T, error) // returns struct and error

  // SELECT * FROM @@table WHERE id=@id
  GetByIDWithoutErr(id int) gen.M // returns data as map, error discarded

  // INSERT INTO @@table (name, age) VALUES (@name, @age)
  InsertValue(name string, age int) (gen.RowsAffected, error) // returns affected rows count and error
}
```

The data type can be combined with other symbols like `*`, `[]`. Each of the following is an **independent alternative signature** (a single interface cannot declare the same method name twice — Go has no overloading):

```go
// alternative signatures for the same raw SQL:
GetByID(id int) (*gen.T, error)  // returns data as pointer and error
GetByID(id int) ([]gen.T, error) // returns data as slice and error
GetByID(id int) ([]*gen.T, error) // returns data as slice of pointer and error
GetByID(id int) ([]gen.M, error) // returns data as slice of map and error
```

## 模板占位符

Gen 提供了一些占位符来生成动态且安全的 SQL

| Name             | Description                                                                                             |
| ---------------- | ------------------------------------------------------------------------------------------------------- |
| `@@table`        | the applied model's table name, inserted at generation time as a quoted Go string                       |
| `@@<name>` | a table/column name taken from a **string** parameter, escaped & quoted at runtime via the DO's `Quote` |
| `@<name>`  | a SQL query parameter bound as `?` from the parameter's value                                           |
| `\@`            | a literal `@` character                                                                                 |

`@@<name>` requires the corresponding method parameter to be a plain (non-array) `string`; anything else fails generation with `variable name must be string :<name> type is <type>`. `@<name>` accepts any type; slices are bound as one argument and expanded by GORM (`WHERE id IN @ids` -> `IN (?, ?, ...)`).

Generated code for `@@<name>` (from gen's test fixtures):

```go
generateSQL.WriteString("select * from users where " + u.Quote(name) + " in ? ")
```

e.g:

```go
type Filter interface {
  // SELECT * FROM @@table WHERE @@column=@value
  FilterWithColumn(column string, value string) (gen.T, error)
}

// Apply the `Filter` interface to `User`, `Company`
g.ApplyInterface(func(Filter) {}, model.User{}, model.Company{})
```

生成代码后，您可以在应用程序中直接使用。

## SQL form markers

The whole comment body can optionally be wrapped to tell Gen how the SQL is used (both markers are case-insensitive and allow the SQL to be additionally wrapped in double quotes):

* `where(...)` — the method is a **condition snippet**: the generated code calls `UnderlyingDB().Where(sql, params...)` instead of `Raw`/`Exec`, so the snippet can be combined with the typed query API (see [Dynamic SQL — Code Snippets](./dynamic_sql.html));
* `sql(...)` — the method is an explicit raw-SQL query (same execution path as no marker; useful to make intent visible or to start the SQL with a `where(` keyword).

```go
type Querier interface {
    // FindByNameAndAge query data by name and age and return it as map
    //
    // where("name=@name AND age=@age")
    FindByNameAndAge(name string, age int) (gen.M, error)
}
```

Without a marker, a method whose comment contains a blank comment line treats the text after the blank line as the SQL and everything above as the method description (this is why the blank line in the examples is required when you describe the method above the SQL).

Application usage skeleton for `FilterWithColumn`: generate with `gen.Config{OutPath: "./query", Mode: gen.WithDefaultQuery}` and apply `Filter` to both models before `g.Execute()`. Substitute your project's imports and DSN. The application opens and checks its own runtime DB, independently of any schema connection used by the generator, then initializes the default queries:

```go
import (
  "context"

  "gorm.io/driver/sqlite"
  "gorm.io/gorm"

  "your_project/query"
)

var ctx = context.Background()

func main() {
  db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
  if err != nil {
    panic(err)
  }
  query.SetDefault(db) // required before query.User/query.Company calls

  user, err := query.User.WithContext(ctx).FilterWithColumn("name", "jinzhu")
  if err != nil {
    return
  }
  _ = user // illustrative skeleton: consume the result in your application
  // SELECT * FROM `users` WHERE `name` = ? ("jinzhu")

  company, err := query.Company.WithContext(ctx).FilterWithColumn("name", "tiktok")
  if err != nil {
    return
  }
  _ = company
  // SELECT * FROM `companies` WHERE `name` = ? ("tiktok")
}
```

All subsequent application snippets on this page share this setup: the generated package includes `WithDefaultQuery`, `query.SetDefault(db)` has run, and `ctx` is defined. They are independent query/SQL illustrations, not standalone programs; import your generated model package and `time` where used, consume returned values, and check each returned error before issuing another query.

## 模板表达式

Gen 提供强大的表达式支持动态条件SQL，目前支持以下表达式：

* `if/else`
* `where`
* `set`
* `for`
* `trim`

### `if/else`

`if/else`表达式中可以使用golang句法的条件语句, 可以像这样写为:

```
{{if cond1}}
  // do something here
{{else if cond2}}
  // do something here
{{else}}
  // do something here
{{end}}
```

例如：

```go
type Querier interface {
  // SELECT * FROM users WHERE
  //  {{if name !=""}}
  //      username=@name AND
  //  {{end}}
  //  role="admin"
  QueryWith(name string) (gen.T,error)
}
```

一个更复杂的案例：

```go
type Querier interface {
  // SELECT * FROM users
  //  {{if user != nil}}
  //      {{if user.ID > 0}}
  //          WHERE id=@user.ID
  //      {{else if user.Name != ""}}
  //          WHERE username=@user.Name
  //      {{end}}
  //  {{end}}
  QueryWith(user *gen.T) (gen.T, error)
}
```

如何使用它：

```go
query.User.WithContext(ctx).QueryWith(&model.User{Name: "zhangqiang"})
// SELECT * FROM users WHERE username="zhangqiang"
```

### `where`

`where`表达式可以让你更轻松的写出SQL查询语句中的`WHERE`子句, 下例为一个简单示例:

```go
type Querier interface {
  // SELECT * FROM @@table
  //  {{where}}
  //      id=@id
  //  {{end}}
  Query(id int) gen.T
}
```

使用生成的代码，您可以使用它：

```go
query.User.WithContext(ctx).Query(10)
// SELECT * FROM users WHERE id=10
```

Here is another complicated case, in this case, you will learn the `WHERE` clause only be inserted if there are any children expressions matched and it can smartly trim unnecessary `and`, `or`, `xor`, `,` inside the `where` clause (case-insensitive, both ends; the `WHERE` keyword is emitted only when something remains).

```go
type Querier interface {
  // SELECT * FROM @@table
  //  {{where}}
  //    {{if !start.IsZero()}}
  //      created_time > @start
  //    {{end}}
  //    {{if !end.IsZero()}}
  //      AND created_time < @end
  //    {{end}}
  //  {{end}}
  FilterWithTime(start, end time.Time) ([]gen.T, error)
}
```

生成的代码可以像这样使用:

```go
var (
  since = time.Date(2022, 10, 1, 0, 0, 0, 0, time.UTC)
  end   = time.Date(2022, 10, 10, 0, 0, 0, 0, time.UTC)
  zero  = time.Time{}
)

query.User.WithContext(ctx).FilterWithTime(since, end)
// SELECT * FROM `users` WHERE created_time > "2022-10-01" AND created_time < "2022-10-10"

query.User.WithContext(ctx).FilterWithTime(since, zero)
// SELECT * FROM `users` WHERE created_time > "2022-10-01"

query.User.WithContext(ctx).FilterWithTime(zero, end)
// SELECT * FROM `users` WHERE created_time < "2022-10-10"

query.User.WithContext(ctx).FilterWithTime(zero, zero)
// SELECT * FROM `users`
```

### `set`

The `set` expression used to generate the `SET` clause for the SQL query, it will trim unnecessary `,` automatically, for example:

```go
// UPDATE @@table
//  {{set}}
//    {{if user.Name != ""}} username=@user.Name, {{end}}
//    {{if user.Age > 0}} age=@user.Age, {{end}}
//    {{if user.Age >= 18}} is_adult=1 {{else}} is_adult=0 {{end}}
//  {{end}}
// WHERE id=@id
UpdateUserFields(user gen.T, id int) (gen.RowsAffected, error)
```

(The method is named `UpdateUserFields` rather than `Update` — `Update` is part of the generated CRUD API and reserved; see [Errors and naming rules](#errors-and-naming-rules) below.)

生成的代码可以像这样使用:

```go
query.User.WithContext(ctx).UpdateUserFields(model.User{Name: "jinzhu", Age: 18}, 10)
// UPDATE users SET username="jinzhu", age=18, is_adult=1 WHERE id=10

query.User.WithContext(ctx).UpdateUserFields(model.User{Name: "jinzhu", Age: 0}, 10)
// UPDATE users SET username="jinzhu", is_adult=0 WHERE id=10

query.User.WithContext(ctx).UpdateUserFields(model.User{Age: 0}, 10)
// UPDATE users SET is_adult=0 WHERE id=10
```

### `for`

`for`表达式遍历切片生成SQL，用下例说明

```go

```

用法:

```go
query.User.WithContext(ctx).Filter([]model.User{
        {Name: "jinzhu", Age: 18, Role: "admin"},
        {Name: "zhangqiang", Age: 18, Role: "admin"},
        {Name: "modi", Age: 18, Role: "admin"},
        {Name: "songyuan", Age: 18, Role: "admin"},
})
// SELECT * FROM users WHERE
//   (username = "jinzhu" AND age=18 AND role LIKE concat("%","admin","%")) OR
//   (username = "zhangqiang" AND age=18 AND role LIKE concat("%","admin","%")) OR
//   (username = "modi" AND age=18 AND role LIKE concat("%","admin","%")) OR
//   (username = "songyuan" AND age=18 AND role LIKE concat("%","admin","%"))
```

### `trim`

The `trim` expression strips one leading and one trailing `and`, `or`, `xor` or `,` (case-insensitive) from whatever its children produced, and emits no SQL keyword. It is useful inside `for` loops that build `or`-separated lists:

```go
type TrimTest interface {
    // select * from @@table where
    // {{trim}}
    //   {{for _, name := range list}} name = @name or {{end}}
    // {{end}}
    TestTrim(list []string) ([]gen.T, error)
}
```

Without `{{trim}}` the generated fragment would end with a dangling `or`. `{{where}}` and `{{set}}` apply the same trimming to their own content automatically.

## <span id="errors-and-naming-rules">Errors and naming rules</span>

Template and SQL problems are reported by the generator with the source location of the method comment (file, line, column) and the offending snippet:

* `unknown syntax: <word>` — a `{{...}}` block that is not `if/else/for/where/set/trim/end`;
* `incomplete SQL` — unbalanced quotes or an unterminated `{{`;
* `template can not use gen keywords` — the words `generateSQL`, `whereClause`, `setClause` are reserved inside templates;
* `variable name must be string :<name> type is <type>` — an `@@<name>` parameter that is not a string;
* `cannot use the same value name in different for loops`.

Method names must not collide with the generated CRUD API (`Save`, `Create`, `Find`, `First`, `Count`, `Delete`, ... — the GORM keyword list), with a field of the applied model, or with a method of another interface applied to the same model. A method whose comment contains `gen:skip` is parsed but **not implemented** — declare it yourself (e.g. to satisfy an existing interface):

```go
type Querier interface {
    // gen:skip
    ExistingMethod(id int) (gen.T, error)
}
```
