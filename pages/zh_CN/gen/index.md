---
title: Gen Guides
layout: page
---

## GEN 指南

[GEN](https://github.com/go-gorm/gen): 更友好 & 更安全 [GORM](https://github.com/go-gorm/gorm) 代码生成。

## 概览

- Idiomatic & Reusable API from Dynamic Raw SQL
- 100% Type-safe DAO API without `interface{}`
- Database To Struct follows GORM conventions
- GORM under the hood, supports all features, plugins, DBMS that GORM supports

## 安装

```sh
go get -u gorm.io/gen
```

## 快速入门

在程序中使用 `gen` 非常简单，具体操作如下：

**1. Write the configuration in golang** (skeleton — substitute your own model package, DSN and import paths):

```go
package main

import (
  "gorm.io/driver/sqlite"
  "gorm.io/gen"
  "gorm.io/gorm"

  "your_project/model"
)

// Dynamic SQL
type Querier interface {
  // SELECT * FROM @@table WHERE name = @name{{if role !=""}} AND role = @role{{end}}
  FilterWithNameAndRole(name, role string) ([]gen.T, error)
}

func main() {
  g := gen.NewGenerator(gen.Config{
    OutPath: "../query",
    Mode: gen.WithoutContext|gen.WithDefaultQuery|gen.WithQueryInterface|gen.WithGeneric, // generate mode
  })

  // gormdb, err := gorm.Open(mysql.Open("root:@(127.0.0.1:3306)/demo?charset=utf8mb4&parseTime=True&loc=Local"))
  // if err != nil { panic(err) }
  gormdb, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
  if err != nil {
    panic(err)
  }
  g.UseDB(gormdb) // reuse your gorm db

  // Generate basic type-safe DAO API for struct `model.User` following conventions
  g.ApplyBasic(model.User{})

  // Generate Type Safe API with Dynamic SQL defined on Querier interface for `model.User` and `model.Company`
  g.ApplyInterface(func(Querier){}, model.User{}, model.Company{})

  // Generate the code
  g.Execute()
}
```

**2. 生成代码**

`go run main.go`

**3. Use the generated code in your project** (usage skeleton — the prerequisites shown in `main` are required for the snippets below: open your application's `*gorm.DB` and register it with `query.SetDefault(db)` before any `query.User`-style default-variable call; results are consumed via `err`/the returned values)

```go
import (
  "gorm.io/driver/sqlite"
  "gorm.io/gorm"

  "your_project/query"
)

func main() {
  // application runtime DB — separate from the generator's schema connection
  // in step 1: both call gorm.Open, but this one runs in your service
  db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
  if err != nil {
    panic(err)
  }
  query.SetDefault(db) // required for the query.User default variables

  // Basic DAO API (direct calls work in the WithoutContext mode generated above;
  // in the default mode start from query.Use(db).User.WithContext(ctx))
  user, err := query.User.Where(query.User.Name.Eq("modi")).First()
  if err != nil {
    return
  }
  _ = user // illustrative skeleton: consume the result in your application

  // Dynamic SQL API
  users, err := query.User.FilterWithNameAndRole("modi", "admin")
  if err != nil {
    return
  }
  _ = users
}
```

> **NOTE**: `g.UseDB(db)` must be called in the **generator** program before `GenerateModel`/`GenerateModelAs` — those read the database schema through the connection and fail with `UseDB() is necessary to generate model struct [...] from database table [...]` when it is missing. `GenerateAllTable` equally requires a real database connection (it lists the tables through the DB), but does not carry that specific guard — without `UseDB` it fails later, at listing the tables. (`GenerateModelFrom` and `ApplyBasic` applied to existing structs do not query the database schema and are exempt.) In the default (context-aware) mode, generated methods are reached through the model's `WithContext`, e.g. `query.User.WithContext(ctx).FilterWithNameAndRole("modi", "admin")`.
