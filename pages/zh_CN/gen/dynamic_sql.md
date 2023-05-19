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
  GetByID(id int) (gen.T, error) // GetByID query data by id and return it as *struct*

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

g := gen.NewGenerator(gen.Config{
  // ... some config
})

// Apply the interface to existing `User` and generated `Employee`
g.ApplyInterface(func(Querier) {}, model.User{}, g.GenerateModel("employee"))

g.Execute()
```

运行上面的配置程序，为您的应用程序生成查询代码。如何使用生成的代码：

```go
import "your_project/query"

func main() {
  user, err := query.User.GetByID(10)

  employees, err := query.Employee.GetByRoles("admin", "manager")

  err := query.User.InsertValue("modi", 18)
}
```

## 代码段

代码片段通常与 [DAO 接口一起使用](./dao.html)

```go
type Querier interface {
  // FindByNameAndAge query data by name and age and return it as map
  //
  // where("name=@name AND age=@age")
  FindByNameAndAge(name string, age int) (gen.M, error)
}

g := gen.NewGenerator(gen.Config{
  // ... some config
})

// Apply the interface to existing `User` and generated `Employee`
g.ApplyInterface(func(Querier) {}, model.User{}, g.GenerateModel("employee"))

g.Execute()
```

Usage:

```go
import "your_project/query"

func main() {
  userMap, err := query.User.Where(query.User.Name.Eq("modi")).FilterWithNameAndRole("modi", "admin")
}
```

## More control

`Gen` 支持有条件的注释并自定义返回的结果，参考 [注释](./sql_annotation.html) 了解更多
