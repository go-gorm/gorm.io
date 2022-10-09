---
title: Type Safe Execute Compiled SQL
layout: page
---

Gen provides type safe execute of compiled SQL, which can effectively avoid SQL injection, and supports dynamic SQL splicing to meet various requirements,The DIY method needs to be defined through the interface. In the method, the specific SQL query logic is described in the way of comments. Simple WHERE queries can be wrapped in `where()`. When using complex queries, you need to write complete SQL. You can directly wrap them in `sql()` or write SQL directly. If there are some comments on the method, just add a blank line comment in the middle.

```go
type Method interface {
    // where("name=@name and age=@age")
    SimpleFindByNameAndAge(name string, age int) (gen.T, error)

    // FindUserToMap query by id and return id->instance
    //
    // sql(select * from users where id=@id)
    FindUserToMap(id int) (gen.M, error)

    // InsertValue this is method comments
    //
    //insert into users (name,age) values (@name,@age)
    InsertValue(age int, name string) error
}
```

Usage:

```go
g := gen.NewGenerator(gen.Config{
    // ... some config
})

// implement model.Method on table "user" and "student"
g.ApplyInterface(func(method model.Method) {}, model.User{}, g.GenerateModel("student"))

g.Execute()
```
