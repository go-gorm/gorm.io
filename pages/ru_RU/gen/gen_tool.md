---
title: Gen Tool
layout: page
---

Gen Tool is a single binary without dependencies can be used to generate structs from database

## Install

```shell
go install gorm.io/gen/tools/gentool@latest
```

## Version and Go compatibility

The tool module (`gorm.io/gen/tools/gentool`, currently **v0.0.3**) and the library module (`gorm.io/gen`, currently **v0.3.29**) version independently — check both when reporting issues.

The tool module and its current dependency set (e.g. `golang.org/x/tools` v0.40.0) declare `go 1.24.0`, so building gentool requires **Go 1.24 or newer**; the generated code and the `gorm.io/gen` library itself only require **Go 1.18+** (`-useAny` likewise only needs Go 1.18 in the target module). If you write your own generator program importing `gorm.io/gen` v0.3.29 under a recent toolchain and hit build errors inside `golang.org/x/tools`, bump `golang.org/x/tools` in your module to a version compatible with your toolchain (gen's minimum pin v0.17.0 predates current compilers).

## Usage

```shell
 gentool -h

 Usage of gentool:
  -c string
        is path for gen.yml
  -db string
        input mysql|postgres|sqlite|sqlserver|clickhouse. consult[https://gorm.io/docs/connecting_to_the_database.html] (default "mysql")
  -dsn string
        consult[https://gorm.io/docs/connecting_to_the_database.html]
  -fieldCoverable
        generate with pointer when field has default value
  -fieldNullable
        generate with pointer when field is nullable
  -fieldSignable
        detect integer field's unsigned type, adjust generated data type
  -fieldWithDefaultTag
        generate field with gorm default tag
  -fieldWithIndexTag
        generate field with gorm index tag
  -fieldWithTypeTag
        generate field with gorm column type tag
  -modelPkgName string
        generated model code's package name
  -onlyModel
        only generate models (without query file)
  -outFile string
        query code file name, default: gen.go
  -outPath string
        specify a directory for output (default "./dao/query")
  -tables string
        enter the required data table or leave it blank
  -unitTestTemplate string
        custom unit test template file path for query code
  -useAny
        emit "any" instead of "interface{}" in generated code (requires Go 1.18+)
  -withDefaultQuery
        create default query in generated code
  -withGeneric
        generate code with generic
  -withQueryInterface
        generate code with exported interface object
  -withUnitTest
        generate unit test for query code
  -withoutContext
        generate code without context constrain

```

#### c

Path to a YAML configuration file. When `-c` is set, the configuration file **completely replaces command-line flags** — every other flag on the same invocation is ignored, even if set. Use either flags or a config file, not both.

#### db

Specify driver dialector, default value "mysql", refer: https://gorm.io/docs/connecting_to_the_database.html

Supported: `mysql`, `postgres`, `sqlite`, `sqlserver`, `clickhouse`. (The tool's own error message for an unknown `-db` omits `clickhouse`, but it is supported.)

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

Generated query code file name, default: gen.go. It names the **entry file** (`Use`/`SetDefault`/`Q`) only; every model always gets its own `<model>.gen.go` regardless.

#### outPath

Specify a directory for output (default "./dao/query")

#### tables

Specify tables want to be generated from, default all tables. Names are comma-separated, whitespace-trimmed, empty entries dropped.

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
  # input mysql or postgres or sqlite or sqlserver or clickhouse
  db  : "mysql"
  # enter the required data table as a LIST, or leave it empty for all tables
  # tables:
  #   - orders
  #   - users
  tables:
  # only generate models (without query file)
  onlyModel : false
  # specify a directory for output
  outPath : "./dao/query"
  # query code file name, default: gen.go
  outFile : ""
  # generate unit test for query code
  withUnitTest : false
  # custom unit test template file path for query code
  unitTestTemplate : ""
  # generated model code's package name
  modelPkgName : ""
  # generate with pointer when field is nullable
  fieldNullable : false
  # generate with pointer when field has default value
  fieldCoverable : false
  # generate field with gorm index tag
  fieldWithIndexTag : false
  # generate field with gorm column type tag
  fieldWithTypeTag : false
  # generate field with gorm default tag
  fieldWithDefaultTag : false
  # detect integer field's unsigned type, adjust generated data type
  fieldSignable : false
  # create default query in generated code
  withDefaultQuery : false
  # generate code without context constrain
  withoutContext : false
  # generate code with exported interface object
  withQueryInterface : false
  # generate code with generic
  withGeneric : false
  # emit "any" instead of "interface{}" in generated code (requires Go 1.18+)
  useAny : false
```

Note that `tables` must be a **list** — a scalar string fails YAML decoding with `cannot unmarshal !!str ... into []string`.
