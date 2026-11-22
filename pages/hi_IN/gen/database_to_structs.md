---
title: Database To Structs
layout: page
---

## Quick Start

Gen supports generate structs from databases following GORM conventions (skeleton — substitute your DSN):

```go
package main

import (
  "gorm.io/driver/sqlite"
  "gorm.io/gen"
  "gorm.io/gorm"
)

func main() {
  g := gen.NewGenerator(gen.Config{
    OutPath: "../query",
    Mode: gen.WithoutContext|gen.WithDefaultQuery|gen.WithQueryInterface, // generate mode
  })

  // gormdb, err := gorm.Open(mysql.Open("root:@(127.0.0.1:3306)/demo?charset=utf8mb4&parseTime=True&loc=Local"))
  // if err != nil { panic(err) }
  gormdb, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
  if err != nil {
    panic(err)
  }
  g.UseDB(gormdb) // reuse your gorm db

  // Generate basic type-safe DAO API for struct `model.User` following conventions

  g.ApplyBasic(
  // Generate struct `User` based on table `users`
  g.GenerateModel("users"),

  // Generate struct `Employee` based on table `users`
 g.GenerateModelAs("users", "Employee"),


// Generate struct `User` based on table `users` and generating options
g.GenerateModel("users", gen.FieldIgnore("address"), gen.FieldType("id", "int64")),

// Generate struct `Customer` based on table `customer` and generating options
// customer table may have a tags column, it can be JSON type, gorm/gen tool can generate for your JSON data type
g.GenerateModel("customer", gen.FieldType("tags", "datatypes.JSON")),

  )
g.ApplyBasic(
// Generate structs from all tables of current database
g.GenerateAllTable()...,
)
  // Generate the code
  g.Execute()
}

```

## Methods Template

When generating structs from database, you can also generate methods with a template for them by the way, for example:

```Go
type CommonMethod struct {
    ID   int32
    Name *string
}

func (m *CommonMethod) IsEmpty() bool {
    if m == nil {
        return true
    }
    return m.ID == 0
}

func (m *CommonMethod) GetName() string {
    if m == nil || m.Name == nil {
        return ""
    }
    return *m.Name
}

// Add IsEmpty method to the generated `People` struct
// (note the addressable receiver — (&CommonMethod{}).IsEmpty — IsEmpty has a pointer receiver)
g.GenerateModel("people", gen.WithMethod((&CommonMethod{}).IsEmpty))

// Add all methods defined on `CommonMethod` to the generated `User` struct
g.GenerateModel("user", gen.WithMethod(CommonMethod{}))
```

The generated code would look like this:

```go
// Generated Person struct
type Person struct {
  // ...
}

func (m *Person) IsEmpty() bool {
  if m == nil {
    return true
  }
  return m.ID == 0
}


// Generated User struct
type User struct {
  // ...
}

func (m *User) IsEmpty() bool {
  if m == nil {
    return true
  }
  return m.ID == 0
}

func (m *User) GetName() string {
  if m == nil || m.Name == nil {
    return ""
  }
  return *m.Name
}
```
### DIY TableName

When generating structs from database, you can also diy table name for them by the way, for example:

```Go
type CommonMethod struct {
    ID   int32
    Name *string
}

// Alternative 1: fixed table name
func (m CommonMethod) TableName() string {
    return "@@table"
}

// Alternative 2: table name with gorm NamingStrategy — an INDEPENDENT variant,
// declared on a separate type (Go does not allow two methods named TableName
// on one type):
type CommonMethodWithNamer struct {
    CommonMethod
}

func (m CommonMethodWithNamer) TableName(namer schema.Namer) string {
    if namer == nil {
        return "@@table"
    }
    return namer.TableName("@@table")
}

// DIY TableName method (alternative 1) for the generated `User` struct
g.GenerateModel("user", gen.WithMethod(CommonMethod{}.TableName))

// DIY TableName method (alternative 1) for all generated structs
g.WithOpts(gen.WithMethod(CommonMethod{}.TableName))

// DIY namer-aware TableName method (alternative 2) for all generated structs
g.WithOpts(gen.WithMethod(CommonMethodWithNamer{}.TableName))

// Set Default DIY TableName method for the generated all struct
g.WithOpts(gen.WithMethod(gen.DefaultMethodTableWithNamer))

```

## Field Options

Following are options that can be used during `GenerateModel`/`GenerateModelAs`

```go
FieldNew           // create new a field
FieldIgnore        // ignore field
FieldIgnoreReg     // ignore field (match with regexp)
FieldRename        // rename field in the struct
FieldComment       // specify field comment in generated struct
FieldType          // specify the field type
FieldTypeReg       // specify field type (match with regexp)
FieldGenType       // specify field gen type
FieldGenTypeReg    // specify field gen type (match with regexp)
FieldTag           // specify gorm and json tag
FieldJSONTag       // specify json tag
FieldJSONTagWithNS // specify json tag with name strategy
FieldGORMTag       // specify gorm tag
FieldGORMTagReg    // specify gorm tag for columns matching a regexp (since v0.3.26)
FieldNewTag        // append new tag
FieldNewTagWithNS  // specify the new tag with name strategy
FieldTrimPrefix    // trim column prefix
FieldTrimSuffix    // trim column suffix
FieldAddPrefix     // add the prefix to struct field's name
FieldAddSuffix     // add the suffix to struct field's name
FieldRelate        // specify relationship with other tables
FieldRelateModel   // specify the relationship with existing models
```

Additional released field options:

```go
// FieldModify rewrites the generated field definition with a custom function
FieldModify(opt func(Field) Field)

// FieldFilter drops the field when the function returns nil
FieldFilter(opt func(Field) Field)

// WithDataTypesNullType maps basic types to datatypes.Null[T]
// (also available as a Config/Generator option: g.WithDataTypesNullType(true), since v0.3.27)
WithDataTypesNullType(all bool)
```

```go
// example: prefix every generated field name
g.GenerateModel("users", gen.FieldModify(func(f gen.Field) gen.Field {
    f.Name = "col_" + f.Name
    return f
}))
```

## Global Generating Options

Gen has some global options that could be setup in the `gen.Config`, here is the list:

```go
g := gen.NewGenerator(gen.Config{
  // if you want the nullable field generation property to be pointer type, set FieldNullable true
  FieldNullable: true,
  // if you want to assign field which has a default value in the `Create` API, set FieldCoverable true, reference: https://gorm.io/docs/create.html#Default-Values
  FieldCoverable: true,
  // if you want to generate field with unsigned integer type, set FieldSignable true
  FieldSignable: true,
  // if you want to generate index tags from database, set FieldWithIndexTag true
  FieldWithIndexTag: true,
  // if you want to generate type tags from database, set FieldWithTypeTag true
  FieldWithTypeTag: true,
  // if you need unit tests for query code, set WithUnitTest true
  WithUnitTest: true,
})
```

```go
// WithDbNameOpts set get database name function
WithDbNameOpts(opts ...model.SchemaNameOpt)

// WithTableNameStrategy specify table name naming strategy, only work when syncing table from db
WithTableNameStrategy(ns func(tableName string) (targetTableName string))

// WithModelNameStrategy specify model struct name naming strategy, only work when syncing table from db
// If an empty string is returned, the table will be ignored
WithModelNameStrategy(ns func(tableName string) (modelName string))

// WithFileNameStrategy specify file name naming strategy, only work when syncing table from db
WithFileNameStrategy(ns func(tableName string) (fileName string))

// WithJSONTagNameStrategy specify json tag naming strategy
WithJSONTagNameStrategy(ns func(columnName string) (tagContent string))

// WithDataTypeMap specify data type mapping relationship, only work when syncing table from db
WithDataTypeMap(newMap map[string]func(gorm.ColumnType) (dataType string))

// WithImportPkgPath specify import package path
WithImportPkgPath(paths ...string)

// WithOpts specify global model options
WithOpts(opts ...ModelOpt)
```
### Ignore Table
By `WithTableNameStrategy`, you can ignore some tables that do not need to be generated, such as tables starting with `_`.

```go
g.WithTableNameStrategy(func(tableName string) (targetTableName string) {
        if strings.HasPrefix(tableName, "_") { //Just return an empty string and the table will be ignored.
            return ""
        }
        return tableName
    })
```

An ignored table is logged (`ignore table <x>`) and yields a `nil` entry from `GenerateAllTable`; such nil entries are safely skipped by `ApplyBasic`, so `g.ApplyBasic(g.GenerateAllTable()...)` keeps working. Passing a non-nil argument that is not a struct is still an error (and `ApplyInterface` panics with `check struct fail` in that case).

### Generate From Object

Besides database tables, a model can be described in code by implementing the `helper.Object` and `helper.Field` interfaces from the `gorm.io/gen/helper` package, then applied with `GenerateModelFrom`:

```go
import "gorm.io/gen/helper"

// implement helper.Object (TableName/StructName/FileName/ImportPkgPaths/Fields)
// and helper.Field (Name/Type/ColumnName/GORMTag/JSONTag/Tag/Comment) yourself,
// e.g. backed by an API definition or a protobuf message.

g.ApplyBasic(g.GenerateModelFrom(myUserObject))
```

`helper.CheckObject(obj)` validates an object before handing it to the generator. The `helper` package also exposes the clause builders used by DIY-method templates (`helper.IfClause`, `helper.WhereClause`, `helper.SetClause`, `helper.JoinWhereBuilder`, `helper.JoinSetBuilder`, `helper.JoinTrimAllBuilder`, `helper.NewJoinTblExpr`) for advanced template customization.

### Data Mapping

Specify datatype mapping between field type and db column type. Mapping keys are the database data types as reported by `gorm.ColumnType`, and the function may return pointer types.

```go
    var dataMap = map[string]func(gorm.ColumnType) (dataType string){
        // int mapping
        "int": func(columnType gorm.ColumnType) (dataType string) {
            if n, ok := columnType.Nullable(); ok && n {
                return "*int32"
            }
            return "int32"
        },

        // bool mapping
        "tinyint": func(columnType gorm.ColumnType) (dataType string) {
            ct, _ := columnType.ColumnType()
            if strings.HasPrefix(ct, "tinyint(1)") {
                return "bool"
            }
            return "byte"
        },
    }

    g.WithDataTypeMap(dataMap)
```
## Generate From Sql

Gen supports generate structs from sql following GORM conventions, it can be used like:

```go
package main

import (
    "gorm.io/gorm"
    "gorm.io/rawsql"
)

func main() {
  g := gen.NewGenerator(gen.Config{
    OutPath: "../query",
    Mode: gen.WithoutContext|gen.WithDefaultQuery|gen.WithQueryInterface, // generate mode
  })
  // https://github.com/go-gorm/rawsql/blob/master/tests/gen_test.go
  gormdb, err := gorm.Open(rawsql.New(rawsql.Config{
        //SQL:      rawsql,                      //create table sql
        FilePath: []string{
            //"./sql/user.sql", // create table sql file
            "./test_sql", // create table sql file directory
        },
    }))
  if err != nil {
    panic(err)
  }
  g.UseDB(gormdb) // reuse your gorm db

  // Generate basic type-safe DAO API for struct `model.User` following conventions

  g.ApplyBasic(
  // Generate struct `User` based on table `users`
  g.GenerateModel("users"),

  // Generate struct `Employee` based on table `users`
 g.GenerateModelAs("users", "Employee"),

  )
g.ApplyBasic(
// Generate structs from all tables of current database
g.GenerateAllTable()...,
)
  // Generate the code
  g.Execute()
}

```
