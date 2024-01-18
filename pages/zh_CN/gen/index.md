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

**1. 在 Go 中写入配置**

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

**2. 生成代码**

`go run main.go`

**3. 在您的项目中使用生成的代码**

```go
import "your_project/query"

func main() {
  // Basic DAO API
  user, err := query.User.Where(u.Name.Eq("modi")).First()

  // Dynamic SQL API
  users, err := query.User.FilterWithNameAndRole("modi", "admin")
}
```
