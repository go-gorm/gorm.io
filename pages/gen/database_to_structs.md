---
title: Database To Structs
layout: page
---

Gen supports generate structs from databases following GORM conventions, it can be used like:

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

## Field Options

Following are options that can be used during `GenerateModel`/`GenerateModelAs`

```go
FieldNew           // create new field
FieldIgnore        // ignore field
FieldIgnoreReg     // ignore field (match with regexp)
FieldRename        // rename field in struct
FieldComment       // specify field comment in generated struct
FieldType          // specify field type
FieldTypeReg       // specify field type (match with regexp)
FieldGenType       // specify field gen type
FieldGenTypeReg    // specify field gen type (match with regexp)
FieldTag           // specify gorm and json tag
FieldJSONTag       // specify json tag
FieldJSONTagWithNS // specify new tag with name strategy
FieldGORMTag       // specify gorm tag
FieldNewTag        // append new tag
FieldNewTagWithNS  // specify new tag with name strategy
FieldTrimPrefix    // trim column prefix
FieldTrimSuffix    // trim column suffix
FieldAddPrefix     // add prefix to struct field's name
FieldAddSuffix     // add suffix to struct field's name
FieldRelate        // specify relationship with other tables
FieldRelateModel   // specify relationship with exist models
```

## Global Generating Options

Gen has some default options could be setup in the `gen.Config`, here is the sample:

```go
g := gen.NewGenerator(gen.Config{
  // if you want the nullable field generation property to be pointer type, set FieldNullable true
  FieldNullable: true,
  // if you want to assign field which has default value in `Create` API, set FieldCoverable true, reference: https://gorm.io/docs/create.html#Default-Values
  FieldCoverable: true,
  // if you want generate field with unsigned integer type, set FieldSignable true
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
```

eg. **Data Mapping**

Specify data mapping relationship to be whatever you want.

```go
dataMap := map[string]func(detailType string) (dataType string){
  "int": func(detailType string) (dataType string) { return "int64" },
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
