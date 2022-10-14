---
title: Gen Guides
layout: page
---

## GEN Guides

[GEN](https://github.com/go-gorm/gen): Friendly & Safer [GORM](https://github.com/go-gorm/gorm) powered by Code Generation.

## 概览

- Idiomatic & Reusable API from Dynamic Raw SQL
- 100% Type-safe DAO API without `interface{}`
- Database To Struct follows GORM conventions
- GORM under the hood, supports all features, plugins, DBMS that GORM supports

## 安装

```sh
go get -u gorm.io/gen
```

## Quick start

It is quite straightforward to use `gen` for your application, here is how it works:

**1. Write the configuration in golang**

```go
package main

import "gorm.io/gen"

// Dynamic SQL
type Querier interface {
  // SELECT * FROM @@table WHERE name = @name{{if role !=""}} AND role = @role{{end}}
  FilterWithNameAndRole(name, role string) ([]gen.T, error)
}

func main() {
  g := gen.NewGenerator(gen.Config{
    OutPath: "../query",
    Mode: gen.WithoutContext|gen.WithDefaultQuery|gen.WithQueryInterface, // generate mode
  })

  // gormdb, _ := gorm.Open(mysql.Open("root:@(127.0.0.1:3306)/demo?charset=utf8mb4&parseTime=True&loc=Local"))
  g.UseDB(gormdb) // reuse your gorm db

  // Generate basic type-safe DAO API for struct `model.User` following conventions
  g.ApplyBasic(model.User{})

  // Generate Type Safe API with Dynamic SQL defined on Querier interface for `model.User` and `model.Company`
  g.ApplyInterface(func(Querier){}, model.User{}, model.Company{})

  // Generate the code
  g.Execute()
}
```

**2. Generate Code**

`go run main.go`

**3. Use the generated code in your project**

```go
import "your_project/query"

func main() {
  // Basic DAO API
  user, err := query.User.Where(u.Name.Eq("modi")).First()

  // Dynamic SQL API
  users, err := query.User.FilterWithNameAndRole("modi", "admin")
}
```
