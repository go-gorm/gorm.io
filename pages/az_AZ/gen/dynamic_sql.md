---
title: Dynamic SQL
layout: page
---

Gen allows generate fully-type-safe idiomatic Go code from Raw SQL, it uses annotations on interfaces, those interfaces could be applied to multiple models during code generation.

Not only your tuned SQL queries but also SQL snippets are allowed to be shared and reused, let's take an example:

## Raw SQL

```go
type Querier interface {
  // SELECT * FROM @@table WHERE id=@id
  GetByID(id int) (gen.T, error) // GetByID query data by id and return it as *struct*

  // GetUsersByRole query data by roles and return it as *slice of pointer*
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

Run the above configuration program to generate the query interface codes for your application, and use the generated code like:

```go
import "your_project/query"

func main() {
  user, err := query.User.GetByID(10)

  employees, err := query.Employee.GetByRoles("admin", "manager")

  err := query.User.InsertValue("modi", 18)
}
```

## Code Snippets

Code Snippets are usually used with the [DAO interface](./dao.html) together

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

`Gen` support conditionally annotations and customize the returning results, refer [Annotation](./sql_annotation.html) to learn more
