---
title: 从数据库生成结构
layout: page
---

## Quick Start

Gen 支持所有GORM Driver从数据库生成结构, 使用示例:

```go
package main

import "gorm.io/gen"

func main() {
  g := gen.NewGenerator(gen.Config{
    OutPath: "../query",
    Mode: gen.WithoutContext|gen.WithDefaultQuery|gen.WithQueryInterface, // 生成模式
  })

  // gormdb, _ := gorm.Open(mysql.Open("root:@(127.0.0.1:3306)/demo?charset=utf8mb4&parseTime=True&loc=Local"))
  g.UseDB(gormdb) // reuse your gorm db

  // 按照约定为结构体 `model.User` 生成类型安全的 DAO API
  g.ApplyBasic(
    // 根据 `user` 表生成结构 `User` 
    g.GenerateModel("users"),

    // 根据 `user` 表生成结构 `Employee` 
    g.GenerateModelAs("users", "Employee"),

    // 根据 `user` 表和生成时选项生成结构 `User`
    g.GenerateModel("users", gen.FieldIgnore("address"), gen.FieldType("id", "int64")),
  )

  g.ApplyBasic(
    // 从当前数据库中生成所有表的结构
    g.GenerateAllTable()...,
  )

  // 生成代码
  g.Execute()
}

```

## 模板方法

当从数据库生成结构时，您也可以通过面的方式，给生成的model添加模板方法，例如：

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

// 为生成的 `People` 结构添加 `IsEmpty` 方法
g.GenerateModel("people", gen.WithMethod(CommonMethod{}.IsEmpty))

// 将 `CommonMethod` 上定义的所有方法添加到生成的 `User` 结构中
g.GenerateModel("user", gen.WithMethod(CommonMethod{}))
```

生成的代码看起来像这样：

```go
// 生成的 Person 结构
type Person struct {
  // ...
}

func (m *Person) IsEmpty() bool {
  if m == nil {
    return true
  }
  return m.ID == 0
}


// 生成的 User 结构
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
### 自定义表名称

当从数据库生成结构时，您也可以通过实现自己的TableName方法，例如：

```Go
type CommonMethod struct {
    ID   int32
    Name *string
}

// TableName 
func (m CommonMethod) TableName() string {
    return "@@table"
}

// TableName table name with gorm NamingStrategy
func (m CommonMethod) TableName(namer schema.Namer) string {
    if namer == nil {
        return "@@table"
    }
    return namer.TableName("@@table")
}

// DIY TableName method for the generated `User` struct
g.GenerateModel("user", gen.WithMethod(CommonMethod{}.TableName))

// DIY TableName method for the generated all struct
g.WithOpts(gen.WithMethod(CommonMethod{}.TableName))

// Set Default DIY TableName method for the generated all struct
g.WithOpts(gen.WithMethod(gen.DefaultMethodTableWithNamer))

```

## 字段选项

以下是调用 `GenerateModel`/`GenerateModelAs` 时可以使用的选项

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
FieldNewTag        // append new tag
FieldNewTagWithNS  // specify the new tag with name strategy
FieldTrimPrefix    // trim column prefix
FieldTrimSuffix    // trim column suffix
FieldAddPrefix     // add the prefix to struct field's name
FieldAddSuffix     // add the suffix to struct field's name
FieldRelate        // specify relationship with other tables
FieldRelateModel   // specify the relationship with existing models
```

## 全局生成选项

Gen 有一些全局选项可以在 `gen.Config`中设置：

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

### 数据类型映射

指定model属性类型和 db 字段类型之间的映射关系。

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
  gormdb, _ := gorm.Open(rawsql.New(rawsql.Config{
        //SQL:      rawsql,                      //create table sql
        FilePath: []string{
            //"./sql/user.sql", // create table sql file
            "./test_sql", // create table sql file directory
        },
    }))
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
