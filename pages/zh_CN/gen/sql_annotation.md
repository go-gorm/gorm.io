---
title: Annotation Syntax
layout: page
---

在接口的方法上的注释，Gen将解析它们并为应用的结构生成查询 API。

Gen 提供一些有条件的 SQL 动态支持，让我们从三个方面介绍它们：

* 返回结果
* 模板占位符
* 模板表达式

## 返回结果

Gen 允许配置返回的结果类型，它支持以下四种基本类型。

| Option           | Description                                               |
| ---------------- | --------------------------------------------------------- |
| gen.T            | returns struct                                            |
| gen.M            | returns map                                               |
| gen.RowsAffected | returns rowsAffected returned from database (type: int64) |
| error            | returns error if any                                      |

e.g:

```go
type Querier interface {
  // SELECT * FROM @@table WHERE id=@id
  GetByID(id int) (gen.T, error) // returns struct and error

  // SELECT * FROM @@table WHERE id=@id
  GetByID(id int) gen.T // returns data as struct

  // SELECT * FROM @@table WHERE id=@id
  GetByID(id int) (gen.M, error) // returns map and error

   // INSERT INTO @@table (name, age) VALUES (@name, @age)
  InsertValue(name string, age int) (gen.RowsAffected, error) // returns affected rows count and error
}
```

这些基本类型可以与其他符号，例如 `* <code>[]`</code>, 例如:

```go
type Querier interface {
  // SELECT * FROM @@table WHERE id=@id
  GetByID(id int) (*gen.T, error) // returns data as pointer and error

  // SELECT * FROM @@table WHERE id=@id
  GetByID(id int) (*[]gen.T, error) // returns data as pointer of slice and error

  // SELECT * FROM @@table WHERE id=@id
  GetByID(id int) ([]*gen.T, error) // returns data as slice of pointer and error

  // SELECT * FROM @@table WHERE id=@id
  GetByID(id int) ([]gen.M, error) // returns data as slice of map and error
}
```

## 模板占位符

Gen 提供了一些占位符来生成动态且安全的 SQL

| Name             | Description                                    |
| ---------------- | ---------------------------------------------- |
| `@@table`        | escaped & quoted table name                    |
| `@@<name>` | escaped & quoted table/column name from params |
| `@<name>`  | SQL query params from params                   |

e.g:

```go
type Filter interface {
  // SELECT * FROM @@table WHERE @@column=@id
  FilterWithColumn(column string, value string) (gen.T, error)
}

// Apply the `Filter` interface to `User`, `Company`
g.ApplyInterface(func(Filter) {}, model.User{}, model.Company{})
```

生成代码后，您可以在应用程序中直接使用。

```go
import "your_project/query"

func main() {
  user, err := query.User.FilterWithColumn("name", "jinzhu")
  // similar like db.Exec("SELECT * FROM `users` WHERE `name` = ?", "jinzhu")

  company, err := query.Company.FilterWithColumn("name", "tiktok")
  // similar like db.Exec("SELECT * FROM `companies` WHERE `name` = ?", "tiktok")
}
```

## 模板表达式

Gen 提供强大的表达式支持动态条件SQL，目前支持以下表达式：

* `if/else`
* `where`
* `set`
* `for`

### `if/else`

The `if/else` expression allows to use golang syntax as condition, it can be written like:

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
query.User.QueryWith(&User{Name: "zhangqiang"})
// SELECT * FROM users WHERE username="zhangqiang"
```

### `where`

The `where` expression make you write the `WHERE` clause for the SQL query easier, let take a simple case as example:

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
query.User.Query(10)
// SELECT * FROM users WHERE id=10
```

Here is another complicated case, in this case, you will learn the `WHERE` clause only be inserted if there are any children expressions matched and it can smartly trim uncessary `and`, `or`, `xor`, `,` inside the `where` clause.

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

The generated code can be used like:

```go
var (
  since = time.Date(2022, 10, 1, 0, 0, 0, 0, time.UTC)
  end   = time.Date(2022, 10, 10, 0, 0, 0, 0, time.UTC)
  zero  = time.Time{}
)

query.User.FilterWithTime(since, end)
// SELECT * FROM `users` WHERE created_time > "2022-10-01" AND created_time < "2022-10-10"

query.User.FilterWithTime(since, zero)
// SELECT * FROM `users` WHERE created_time > "2022-10-01"

query.User.FilterWithTime(zero, end)
// SELECT * FROM `users` WHERE created_time < "2022-10-10"

query.User.FilterWithTime(zero, zero)
// SELECT * FROM `users`
```

### `set`

The `set` expression used to generate the `SET` clause for the SQL query, it will trim uncessary `,` automatically, for example:

```go
// UPDATE @@table
//  {{set}}
//    {{if user.Name != ""}} username=@user.Name, {{end}}
//    {{if user.Age > 0}} age=@user.Age, {{end}}
//    {{if user.Age >= 18}} is_adult=1 {{else}} is_adult=0 {{end}}
//  {{end}}
// WHERE id=@id
Update(user gen.T, id int) (gen.RowsAffected, error)
```

The generated code can be used like:

```go
query.User.Update(User{Name: "jinzhu", Age: 18}, 10)
// UPDATE users SET username="jinzhu", age=18, is_adult=1 WHERE id=10

query.User.Update(User{Name: "jinzhu", Age: 0}, 10)
// UPDATE users SET username="jinzhu", is_adult=0 WHERE id=10

query.User.Update(User{Age: 0}, 10)
// UPDATE users SET is_adult=0 WHERE id=10
```

### `for`

The `for` expression iterates over a slice to generate the SQL, let's explain by example

```go
// SELECT * FROM @@table
// {{where}}
//   {{for _,user:=range user}}
//     {{if user.Name !="" && user.Age >0}}
//       (username = @user.Name AND age=@user.Age AND role LIKE concat("%",@user.Role,"%")) OR
//     {{end}}
//   {{end}}
// {{end}}
Filter(users []gen.T) ([]gen.T, error)
```

Usage:

```go
query.User.Filter([]User{
        {Name: "jinzhu", Age: 18, Role: "admin"},
        {Name: "zhangqiang", Age: 18, Role: "admin"},
        {Name: "modi", Age: 18, Role: "admin"},
        {Name: "songyuan", Age: 18, Role: "admin"},
})
// SELECT * FROM users WHERE
//   (username = "jinzhu" AND age=18 AND role LIKE concat("%","admin","%")) OR
//   (username = "zhangqiang" AND age=18 AND role LIKE concat("%","admin","%"))
//   (username = "modi" AND age=18 AND role LIKE concat("%","admin","%")) OR
//   (username = "songyuan" AND age=18 AND role LIKE concat("%","admin","%"))
```
