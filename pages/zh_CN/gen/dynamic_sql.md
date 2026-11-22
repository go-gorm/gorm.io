---
title: Dynamic SQL
layout: page
---

通过接口上添加注释的方式，Gen 允许从 Raw SQL 生成完全安全的通用 Go 代码， 这些接口可以在代码生成过程中应用于多个model。

不仅支持完整的 SQL，也支持SQL 代码片段生成使用，让我们举一个例子：

## Raw SQL

```go
type Querier interface {
  // SELECT * FROM @@table WHERE id=@id
  GetByID(id int) (gen.T, error) // GetByID query data by id and return it as struct

  // GetByRoles query data by roles and return it as *slice of pointer*
  //   (The below blank line is required to comment for the generated method)
  //
  // SELECT * FROM @@table WHERE role IN @rolesName
  GetByRoles(rolesName ...string) ([]*gen.T, error)

  // InsertValue insert value
  //
  // INSERT INTO @@table (name, age) VALUES (@name, @age)
  InsertValue(name string, age int) error
}

// Generator-body skeleton (run this as a one-off program; imports, DSN and the
// model package are your project's):
g := gen.NewGenerator(gen.Config{
  OutPath: "./query",
  Mode:    gen.WithDefaultQuery, // generates the query.SetDefault/default variables
})

// the schema DB is required BEFORE GenerateModel — the generator reads the
// table structure through it (this is the generation-time connection, not your
// application's runtime DB):
// schemaDB, err := gorm.Open(mysql.Open("..."), &gorm.Config{})
schemaDB, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
if err != nil {
  panic(err)
}
g.UseDB(schemaDB)

// Apply the interface to existing `User` and generated `Employee`
g.ApplyInterface(func(Querier) {}, model.User{}, g.GenerateModel("employee"))

g.Execute()
```

Run the above configuration program to generate the query interface codes for your application. The following usage snippets share this preamble — your application opens its own runtime `*gorm.DB` (a separate connection from the generator's schema DB above) and registers it with the generated package; `ctx` is defined once:

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
    query.SetDefault(db) // wires the query.User default variables

    user, err := query.User.WithContext(ctx).GetByID(10)
    if err != nil {
        return
    }
    _ = user // illustrative skeleton: consume the result in your application

    employees, err := query.Employee.WithContext(ctx).GetByRoles("admin", "manager")
    if err != nil {
        return
    }
    _ = employees

    err = query.User.WithContext(ctx).InsertValue("modi", 18)
    if err != nil {
        return
    }
}
```

Two rules the generated code imposes:

* DIY methods are generated on the per-model DO type, and in the default (context-aware) mode that type is reached through the model's `WithContext` — `query.User.WithContext(ctx).GetByID(10)`. Calling `query.User.GetByID(10)` directly does not compile unless you generate with the `WithoutContext` mode.
* A `gen.T` result is the model struct itself; write `*gen.T`, `[]gen.T` or `[]*gen.T` in the interface signature to change the generated result shape (`(result *model.User)`, `(result []model.User)`, `(result []*model.User)`).

## Generated-file layout

`g.Execute()` writes one `<model>.gen.go` per applied model into `OutPath` (e.g. `query/users.gen.go`), plus one entry file (`gen.go` by default, name set by `Config.OutFile`). The entry file defines `Use(db)` returning `*Query`, and — when the `WithDefaultQuery` mode is enabled — the package-level `Q` and per-model variables (`query.User`) wired by `query.SetDefault(db)`.

## 代码段

代码片段通常与 [DAO 接口一起使用](./dao.html)

```go
type Querier interface {
  // FindByNameAndAge query data by name and age and return it as map
  //
  // where("name=@name AND age=@age")
  FindByNameAndAge(name string, age int) (gen.M, error)
}

// Generator-body skeleton — same schema-DB setup as in Raw SQL above:
// gen.NewGenerator with OutPath and the desired Mode, g.UseDB(schemaDB) BEFORE
// GenerateModel, then:
g.ApplyInterface(func(Querier) {}, model.User{}, g.GenerateModel("employee"))

g.Execute()
```

Usage (same shared preamble as above — runtime `gorm.Open` + `query.SetDefault(db)`
+ defined `ctx`; repeated here for readability):

```go
userMap, err := query.User.WithContext(ctx).
    Where(query.User.Name.Eq("modi")).
    FindByNameAndAge("modi", 18)
if err != nil {
    return
}
// SELECT * FROM `users` WHERE `name` = "modi" AND (name = ? AND age = ?) LIMIT 1
_ = userMap
```

The generated snippet method feeds its SQL fragment to the underlying GORM session as an additional `Where` condition, so conditions you chained before it are kept (AND-combined), and it is perfectly fine to call the snippet on its own:

```go
userMap, err := query.User.WithContext(ctx).FindByNameAndAge("modi", 18)
// SELECT * FROM `users` WHERE name = ? AND age = ? LIMIT 1
```

Generated code for the snippet above (note it queries into the `gen.M` map you declared as the return type):

```go
func (u userDo) FindByNameAndAge(name string, age int) (result map[string]interface{}, err error) {
    var params []interface{}

    var generateSQL strings.Builder
    params = append(params, name)
    params = append(params, age)
    generateSQL.WriteString("name=? AND age=? ")

    result = make(map[string]interface{})
    var executeSQL *gorm.DB
    executeSQL = u.UnderlyingDB().Where(generateSQL.String(), params...).Take(result) // ignore_security_alert
    err = executeSQL.Error

    return
}
```

## More control

`Gen` 支持有条件的注释并自定义返回的结果，参考 [注释](./sql_annotation.html) 了解更多
