---
title: Gen Tool
layout: page
---

Gen Tool is a single binary without dependencies can be used to generate structs from database

## Install

```shell
go install gorm.io/gen/tools/gentool@latest
```

## Usage

```shell
 gentool -h

 Usage of gentool:
  -c string
        config file path 
  -db string
        input mysql or postgres or sqlite or sqlserver. consult[https://gorm.io/docs/connecting_to_the_database.html] (default "mysql")
  -dsn string
        consult[https://gorm.io/docs/connecting_to_the_database.html]
  -fieldNullable
        generate with pointer when field is nullable
  -fieldWithIndexTag
        generate field with gorm index tag
  -fieldWithTypeTag
        generate field with gorm column type tag
  -modelPkgName string
        generated model code's package name
  -outFile string
        query code file name, default: gen.go
  -outPath string
        specify a directory for output (default "./dao/query")
  -tables string
        enter the required data table or leave it blank
  -onlyModel
        only generate models (without query file)
  -withUnitTest
        generate unit test for query code
  -fieldSignable
        detect integer field's unsigned type, adjust generated data type

```

#### c

Configuration file name, default value "", command line options have higher priority than configuration file.

#### db

Specify dirver dialector, default value "mysql", refer: https://gorm.io/docs/connecting_to_the_database.html

#### dsn

DSN that used to connect database, refer: https://gorm.io/docs/connecting_to_the_database.html

#### fieldNullable

Generate with pointer when field is nullable

#### fieldWithIndexTag

Generate field with gorm index tag

#### fieldWithTypeTag

Generate field with gorm column type tag

#### modelPkgName

Generated model code's package name.

#### outFile

Genrated query code file name, default: gen.go

#### outPath

Specify a directory for output (default "./dao/query")

#### tables

Specify tables want to genrated from, default all tables.

eg :

    --tables="orders"       # generate from `orders`

    --tables="orders,users" # generate from `orders` and `users`

    --tables=""             # generate from all tables

Generate some tables code.

#### withUnitTest

Generate unit test, default value `false`, options: `false` / `true`

#### fieldSignable

Use signable datatype as field type, default value `false`, options: `false` / `true`

### Example

```shell
gentool -dsn "user:pwd@tcp(localhost:3306)/database?charset=utf8mb4&parseTime=True&loc=Local" -tables "orders,doctor"

gentool -c "./gen.tool"
```

```yaml
version: "0.1"
database:
  # consult[https://gorm.io/docs/connecting_to_the_database.html]"
  dsn : "username:password@tcp(address:port)/db?charset=utf8mb4&parseTime=true&loc=Local"
  # input mysql or postgres or sqlite or sqlserver. consult[https://gorm.io/docs/connecting_to_the_database.html]
  db  : "mysql"
  # enter the required data table or leave it blank.You can input : orders,users,goods
  tables  : "user"
  # specify a directory for output
  outPath :  "./dao/query"
  # query code file name, default: gen.go
  outFile :  ""
  # generate unit test for query code
  withUnitTest  : false
  # generated model code's package name
  modelPkgName  : ""
  # generate with pointer when field is nullable
  fieldNullable : false
  # generate field with gorm index tag
  fieldWithIndexTag : false
  # generate field with gorm column type tag
  fieldWithTypeTag  : false
```
