---
title: Customize Data Types
layout: page
---

GORM 提供了少量接口，使用户能够为 GORM 定义支持的数据类型，这里以 [json](https://github.com/go-gorm/datatypes/blob/master/json.go) 为例

## 实现数据类型

### Scanner / Valuer

自定义的数据类型必须实现 [Scanner](https://pkg.go.dev/database/sql/sql#Scanner) 和 [Valuer](https://pkg.go.dev/database/sql/driver#Valuer) 接口，以便让 GORM 知道如何将该类型接收、保存到数据库

例如:

```go
type JSON json.RawMessage

// 实现 sql.Scanner 接口，Scan 将 value 扫描至 Jsonb
func (j *JSON) Scan(value interface{}) error {
  bytes, ok := value.([]byte)
  if !ok {
    return errors.New(fmt.Sprint("Failed to unmarshal JSONB value:", value))
  }

  result := json.RawMessage{}
  err := json.Unmarshal(bytes, &result)
  *j = JSON(result)
  return err
}

// 实现 driver.Valuer 接口，Value 返回 json value
func (j JSON) Value() (driver.Value, error) {
  if len(j) == 0 {
    return nil, nil
  }
  return json.RawMessage(j).MarshalJSON()
}
```

### GormDataTypeInterface

A customized data type might has different database types for databases, you can implements the `GormDataTypeInterface` to set them up, for example:

```go
type GormDataTypeInterface interface {
  GormDBDataType(*gorm.DB, *schema.Field) string
}

func (JSON) GormDBDataType(db *gorm.DB, field *schema.Field) string {
  // 使用 field.Tag、field.TagSettings 获取字段的 tag
  // 查看 https://github.com/go-gorm/gorm/blob/master/schema/field.go 获取全部的选项

  // 根据不同的数据库驱动返回不同的数据类型
  switch db.Dialector.Name() {
  case "mysql", "sqlite":
    return "JSON"
  case "postgres":
    return "JSONB"
  }
  return ""
}
```

### Clause Expression

Customized data type possible needs specifically SQL which can't use current GORM API, you can define a `Builder` method for the struct to implement interface `clause.Expression`

```go
type Expression interface {
    Build(builder Builder)
}
```

Checkout [JSON](https://github.com/go-gorm/datatypes/blob/master/json.go) for implementation details, usage:

```go
// 根据 Clause Expression 生成 SQL
db.Find(&user, datatypes.JSONQuery("attributes").HasKey("role"))
db.Find(&user, datatypes.JSONQuery("attributes").HasKey("orgs", "orga"))

// MySQL
// SELECT * FROM `users` WHERE JSON_EXTRACT(`attributes`, '$.role') IS NOT NULL
// SELECT * FROM `users` WHERE JSON_EXTRACT(`attributes`, '$.orgs.orga') IS NOT NULL

// PostgreSQL
// SELECT * FROM "user" WHERE "attributes"::jsonb ? 'role'
// SELECT * FROM "user" WHERE "attributes"::jsonb -> 'orgs' ? 'orga'

db.Find(&user, datatypes.JSONQuery("attributes").Equals("jinzhu", "name"))
// MySQL
// SELECT * FROM `user` WHERE JSON_EXTRACT(`attributes`, '$.name') = "jinzhu"

// PostgreSQL
// SELECT * FROM "user" WHERE json_extract_path_text("attributes"::json,'name') = 'jinzhu'
```

## 自定义数据类型集合

我们创建了一个 Github 仓库，用于收集各种自定义数据类型[https://github.com/go-gorm/datatype](https://github.com/go-gorm/datatypes)，非常欢迎同学们的 pull request ;)
