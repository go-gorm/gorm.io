---
title: Gen Guides
layout: page
---
## GEN Guides
[GEN](https://github.com/go-gorm/gen): Friendly & Safer [GORM](https://github.com/go-gorm/gorm) powered by Code Generation.

## Overview

- CRUD or DIY query method code generation
- Auto migration from database to code
- Transactions, Nested Transactions, Save Point, RollbackTo to Saved Point
- Competely compatible with GORM
- Developer Friendly
- Multiple Generate modes

## Installation

To install Gen package, you need to install Go and set your Go workspace first.

1.The first need Go installed(version 1.14,1.14+ is required), then you can use the below Go command to install Gen.

```bash
go get -u gorm.io/gen
```

2.Import it in your code:

```go
import "gorm.io/gen"
```

## Quick start

**Emphasis**: All use cases in this doc are generated under `WithContext` mode. And if you generate code under `WithoutContext` mode, please remove `WithContext(ctx)` before you call any query method, it helps you make code more concise.

```bash
# assume the following code in generate.go file
$ cat generate.go
```

```go
package main

import "gorm.io/gen"

// generate code
func main() {
    // specify the output directory (default: "./query")
    // ### if you want to query without context constrain, set mode gen.WithoutContext ###
    g := gen.NewGenerator(gen.Config{
        OutPath: "../dal/query",
        Mode: gen.WithoutContext|gen.WithDefaultQuery|gen.WithQueryInterface,
        //if you want the nullable field generation property to be pointer type, set FieldNullable true
        /* FieldNullable: true,*/
        //if you want to assign field which has default value in `Create` API, set FieldCoverable true, reference: https://gorm.io/docs/create.html#Default-Values
        /* FieldCoverable: true,*/
        // if you want generate field with unsigned integer type, set FieldSignable true
        /* FieldSignable: true,*/
        //if you want to generate index tags from database, set FieldWithIndexTag true
        /* FieldWithIndexTag: true,*/
        //if you want to generate type tags from database, set FieldWithTypeTag true
        /* FieldWithTypeTag: true,*/
        //if you need unit tests for query code, set WithUnitTest true
        /* WithUnitTest: true, */
    })
  
    // reuse the database connection in Project or create a connection here
    // if you want to use GenerateModel/GenerateModelAs, UseDB is necessary or it will panic
    // db, _ := gorm.Open(mysql.Open("root:@(127.0.0.1:3306)/demo?charset=utf8mb4&parseTime=True&loc=Local"))
    g.UseDB(db)
  
    // apply basic crud api on structs or table models which is specified by table name with function
    // GenerateModel/GenerateModelAs. And generator will generate table models' code when calling Excute.
    g.ApplyBasic(model.User{}, g.GenerateModel("company"), g.GenerateModelAs("people", "Person", gen.FieldIgnore("address")))
    
    // apply diy interfaces on structs or table models
    g.ApplyInterface(func(method model.Method) {}, model.User{}, g.GenerateModel("company"))

    // execute the action of code generation
    g.Execute()
}
```

Generate Mode:

- `gen.WithoutContext` generate code without `WithContext` constraint
- `gen.WithDefaultQuery` generate code with a default global variable `Q` as a singleton
- `gen.WithQueryInterface` generate code with exported interface object

Best Practice: [gendemo](https://github.com/go-gorm/gendemo)
