---
title: Database To Structs
layout: page
---

## Quick Start

Gen 支持所有GORM Driver从数据库生成结构, 使用示例:

```go
// Generate struct `User` based on table `users`
g.GenerateModel("users")

// Generate struct `Employee` based on table `users`
g.GenerateModelAs("users", "Employee")

// Generate struct `User` based on table `users` and generating options
g.GenerateModel("users", gen.FieldIgnore("address"), gen.FieldType("id", "int64"))

// Generate structs from all tables of current database
g.GenerateAllTable()
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

// Add IsEmpty method to the generated `People` struct
g.GenerateModel("people", gen.WithMethod(CommonMethod{}.IsEmpty))

// Add all methods defined on `CommonMethod` to the generated `User` struct
g.GenerateModel("user", gen.WithMethod(CommonMethod))
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
conf.WithOpts(gen.WithMethod(CommonMethod{}.TableName))

// Set Default DIY TableName method for the generated all struct
conf.WithOpts(gen.WithMethod(gen.DefaultMethodTableWithNamer))

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
WithDataTypeMap(newMap map[string]func(detailType string) (dataType string))

// WithNewTagNameStrategy specify new tag naming strategy
WithNewTagNameStrategy(ns func(columnName string) (tagContent string))

// WithImportPkgPath specify import package path
WithImportPkgPath(paths ...string)

// WithOpts specify global model options
WithOpts(opts ...ModelOpt)
```

### 数据类型映射

指定model属性类型和 db 字段类型之间的映射关系。

```go
dataMap := map[string]func(detailType string) (dataType string){
  "int": func(detailType string) (dataType string) {
      return "int64"
  },
  // bool mapping
  "tinyint": func(detailType string) (dataType string) {
    if strings.HasPrefix(detailType, "tinyint(1)") {
      return "bool"
    }
    return "int8"
  },
}

g.WithDataTypeMap(dataMap)
```
