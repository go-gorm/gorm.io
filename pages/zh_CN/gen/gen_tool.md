---
title: Gen Tool
layout: page
---

Gen Tool 是一个没有依赖关系的二进制文件，可以用来从数据库生成结构

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

配置文件名、默认值 ""、命令行选项的优先级高于配置文件。

#### db

指定Driver，默认值“mysql”，referer：https://gorm.io/docs/connecting_to_the_database.html

#### dsn

用于连接数据库的DSN reference: https://gorm.io/docs/connecting_to_the_database.html

#### fieldNullable

当字段允许空时用指针生成

#### fieldWithIndexTag

生成带有gorm index 标签的字段

#### fieldWithTypeTag

生成带有gorm type标签的字段

#### modelPkgName

生成模型代码包名称。

#### outFile

Genrated 查询代码文件名称，默认值：gen.go

#### outPath

指定输出目录(默认 "./dao/query")

#### tables

指定要生成的表名称，默认所有表。

eg :

    --tables="orders"       # generate from `orders`
    
    --tables="orders,users" # generate from `orders` and `users`
    
    --tables=""             # generate from all tables

Generate some tables code.

#### withUnitTest

生成单元测试，默认值 `fals`, 选项: `false` / `true`

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
