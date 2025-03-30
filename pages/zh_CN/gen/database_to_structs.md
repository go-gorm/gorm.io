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
    Mode: gen.WithoutContext|gen.WithDefaultQuery|gen.WithQueryInterface, // generate mode
  })

  // gormdb, _ := gorm.Open(mysql.Open("root:@(127.0.0.1:3306)/demo?charset=utf8mb4&parseTime=True&loc=Local"))
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

## 模板方法

当从数据库生成结构时，您顺便也可以使用模板为它们生成方法，例如：

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
FieldNew           // 创建一个新字段
FieldIgnore        // 忽略字段
FieldIgnoreReg     // 忽略字段 (与正则匹配的)
FieldRename        // 在结构中重命名字段
FieldComment       // 在生成的结构中指定字段注释
FieldType          // 指定字段类型
FieldTypeReg       // 指定字段类型 (与正则匹配的)
FieldGenType       // 指定字段 gen 类型
FieldGenTypeReg    // 指定字段 gen 类型 (与正则匹配的)
FieldTag           // 指定 gorm 和 json tag
FieldJSONTag       // 指定 json tag
FieldJSONTagWithNS // 使用命名策略指定 json tag
FieldGORMTag       // 指定 gorm tag
FieldNewTag        // 添加新 tag
FieldNewTagWithNS  // 使用命令策略指定新 tag
FieldTrimPrefix    // 去除列前缀
FieldTrimSuffix    // 去除列后缀
FieldAddPrefix     // 在结构字段名上添加前缀
FieldAddSuffix     // 在结构字体名上添加后缀
FieldRelate        // 指定与其它表的关系
FieldRelateModel   // 指定与现有模型的关系
```

## 全局生成选项

Gen 有一些全局选项可以在 `gen.Config`中设置：

```go
g := gen.NewGenerator(gen.Config{
  // 如果你希望为可为null的字段生成属性为指针类型, 设置 FieldNullable 为 true
  FieldNullable: true,
  // 如果你希望在 `Create` API 中为字段分配默认值, 设置 FieldCoverable 为 true, 参考: https://gorm.io/docs/create.html#Default-Values
  FieldCoverable: true,
  // 如果你希望生成无符号整数类型字段, 设置 FieldSignable 为 true
  FieldSignable: true,
  // 如果你希望从数据库生成索引标记, 设置 FieldWithIndexTag 为 true
  FieldWithIndexTag: true,
  // 如果你希望从数据库生成类型标记, 设置 FieldWithTypeTag 为 true
  FieldWithTypeTag: true,
  // 如果你需要对查询代码进行单元测试, 设置 WithUnitTest 为 true
  WithUnitTest: true,
})
```

```go
// WithDbNameOpts 设置获取数据库名称方法
WithDbNameOpts(opts ...model.SchemaNameOpt)

// WithTableNameStrategy 指定表名命名策略, 仅在从数据库同步表时工作
WithTableNameStrategy(ns func(tableName string) (targetTableName string))

// WithModelNameStrategy 指定 model 结构名命名策略, 仅在从数据库同步表时工作
// If an empty string is returned, the table will be ignored
WithModelNameStrategy(ns func(tableName string) (modelName string))

// WithFileNameStrategy 指定文件名命名策略, 仅在从数据库同步表时工作
WithFileNameStrategy(ns func(tableName string) (fileName string))

// WithJSONTagNameStrategy 指定 json tag 命名策略
WithJSONTagNameStrategy(ns func(columnName string) (tagContent string))

// WithDataTypeMap 指定数据类型命名策略, 仅在从数据库同步表时工作
WithDataTypeMap(newMap map[string]func(gorm.ColumnType) (dataType string))

// WithImportPkgPath 指定导入包路径
WithImportPkgPath(paths ...string)

// WithOpts 指定全局 model 选项
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

Gen 支持根据 GORM 约定从 SQL 生成 structs，其使用方式如下：

```go
package main

import (
    "gorm.io/gorm"
    "gorm.io/rawsql"
)

func main() {
    g := gen.NewGenerator(gen.Config{
        OutPath: "../query",
        Mode: gen.WithoutContext|gen.WithDefaultQuery|gen.WithQueryInterface, // 生成模式
    })

    // https://github.com/go-gorm/rawsql/blob/master/tests/gen_test.go
    gormdb, _ := gorm.Open(rawsql.New(rawsql.Config{
        //SQL:      rawsql,                      // 建表sql
        FilePath: []string{
            //"./sql/user.sql", // 建表sql文件
            "./test_sql", // 建表sql目录
        },
    }))
    g.UseDB(gormdb) // 重新引用你的 gorm db

    // 按照约定为结构 `model.User` 生成基本类型安全的DAO API
    g.ApplyBasic(
        // 基于 `user` 表生成 `User` 结构
        g.GenerateModel("users"),

        // 基于 `user` 表生成 `Employee` 结构
        g.GenerateModelAs("users", "Employee"),
    )

    g.ApplyBasic(
        // 从当前数据库生成所有表结构
        g.GenerateAllTable()...,
    )

    // 生成代码
    g.Execute()
}`

```
