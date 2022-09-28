---
title: Gen Guides
layout: page
---

## GEN Guides

[GEN](https://github.com/go-gorm/gen): Friendly & Safer [GORM](https://github.com/go-gorm/gorm) powered by Code Generation.

## Overview

- Idiomatic Go Code
- 100% Type-safe API without `interface{}`
- Reusable and Safe API with hand-optimized SQL
- Database To Golang Struct follows GORM conventions
- GORM under the hood, supports all DBMS, features that GORM supports

## Install

```sh
go get -u gorm.io/gen
```

## Quick start

```go
package main

import "gorm.io/gen"

type Querier interface {
    // SELECT * FROM @@table WHERE name = @name AND role = @role
    FilterWithNameAndRole(name, role string) ([]gen.T, error)
}

func main() {
    g := gen.NewGenerator(gen.Config{
        OutPath: "../query",
        Mode: gen.WithoutContext|gen.WithDefaultQuery|gen.WithQueryInterface, // generate mode
    })

    // gormdb, _ := gorm.Open(mysql.Open("root:@(127.0.0.1:3306)/demo?charset=utf8mb4&parseTime=True&loc=Local"))
    g.UseDB(gormdb) // reuse your gorm db

    // Generate basic type-safe API for struct `model.User` following conventions
    g.ApplyBasic(model.User{})

    // Generate Type Safe API with hand-optimized SQL defined on Querier interface for `model.User` and `model.Company`
    g.ApplyInterface(func(Querier){}, model.User{}, model.Company{})

    // Generate the code
    g.Execute()
}
```

Use the generated code in your project

```go
import "your_project/query"

func main() {
    // Basic API
    user, err := query.User.Where(u.Name.Eq("modi")).First()

    // Hand-optimized SQL API
    users, err := query.User.FilterWithNameAndRole("modi", "admin")
}
```

More examples: [gendemo](https://github.com/go-gorm/gendemo)
