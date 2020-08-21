---
title: Data Types
layout: page
---

GORM provides few interfaces that allow users to define well-supported customized data types for GORM, takes [json](https://github.com/go-gorm/datatypes/blob/master/json.go) as an example

## Implements Data Type

### Scanner / Valuer

The customized data type has to implement the [Scanner](https://pkg.go.dev/database/sql/sql#Scanner) and [Valuer](https://pkg.go.dev/database/sql/driver#Valuer) interfaces, so GORM knowns to how to receive/save it into the database

For example:

```go
type JSON json.RawMessage

// Scan scan value into Jsonb, implements sql.Scanner interface
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

// Value return json value, implement driver.Valuer interface
func (j JSON) Value() (driver.Value, error) {
  if len(j) == 0 {
    return nil, nil
  }
  return json.RawMessage(j).MarshalJSON()
}
```

### GormDataTypeInterface

A customized data type might has different database types, you can implements the `GormDataTypeInterface` to set them up, for example:

```go
type GormDataTypeInterface interface {
  GormDBDataType(*gorm.DB, *schema.Field) string
}

func (JSON) GormDBDataType(db *gorm.DB, field *schema.Field) string {
  // use field.Tag, field.TagSettings gets field's tags
  // checkout https://github.com/go-gorm/gorm/blob/master/schema/field.go for all options

  // returns different database type based on driver name
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

Customized data type possible needs specifically SQL which can't use current GORM API, you can define a `Builder` to implement interface `clause.Expression`

```go
type Expression interface {
	Build(builder Builder)
}
```

Checkout [JSON](https://github.com/go-gorm/datatypes/blob/master/json.go) for implementation details

```go
// Generates SQL with clause Expression
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

## Customized Data Types Collections

We created a Github repo for customized data types collections [https://github.com/go-gorm/datatypes](https://github.com/go-gorm/datatypes), pull request welcome ;)
