---
title: Customize Data Types
layout: page
---

GORM provides few interfaces that allow users to define well-supported customized data types for GORM, takes [json](https://github.com/go-gorm/datatypes/blob/master/json.go) as an example

## Implements Customized Data Type

### Scanner / Valuer

The customized data type has to implement the [Scanner](https://pkg.go.dev/database/sql#Scanner) and [Valuer](https://pkg.go.dev/database/sql/driver#Valuer) interfaces, so GORM knowns to how to receive/save it into the database

For example:

```go
type JSON json. RawMessage

// Scan scan value into Jsonb, implements sql. Scanner interface
func (j *JSON) Scan(value interface{}) error {
  bytes, ok := value.([]byte)
  if !ok {
    return errors. New(fmt. Sprint("Failed to unmarshal JSONB value:", value))
  }

  result := json. RawMessage{}
  err := json. Unmarshal(bytes, &result)
  *j = JSON(result)
  return err
}

// Value return json value, implement driver. Valuer interface
func (j JSON) Value() (driver. Value, error) {
  if len(j) == 0 {
    return nil, nil
  }
  return json. RawMessage(j). MarshalJSON()
}
```

There are many third party packages implement the `Scanner`/`Valuer` interface, which can be used with GORM together, for example:

```go
import (
  "github.com/google/uuid"
  "github.com/lib/pq"
)

type Post struct {
  ID     uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4()"`
  Title  string
  Tags   pq.StringArray `gorm:"type:text[]"`
}
```

### GormDataTypeInterface

GORM will read column's database type from [tag](models.html#tags) `type`, if not found, will check if the struct implemented interface `GormDBDataTypeInterface` or `GormDataTypeInterface` and will use its result as data type

```go
type GormDataTypeInterface interface {
  GormDataType() string
}

type GormDBDataTypeInterface interface {
  GormDBDataType(*gorm.DB, *schema.Field) string
}
```

The result of `GormDataType` will be used as the general data type and can be obtained from `schema.Field`'s field `DataType`, which might be helpful when [writing plugins](write_plugins.html) or [hooks](hooks.html) for example:

```go
func (JSON) GormDataType() string {
  return "json"
}

type User struct {
  Attrs JSON
}

func (user User) BeforeCreate(tx *gorm.DB) {
  field := tx.Statement.Schema.LookUpField("Attrs")
  if field.DataType == "json" {
    // do something
  }
}
```

`GormDBDataType` usually returns the right data type for current driver when migrating, for example:

```go
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

If the struct hasn't implemented the `GormDBDataTypeInterface` or `GormDataTypeInterface` interface, GORM will guess its data type from the struct's first field, for example, will use `string` for `NullString`

```go
type NullString struct {
  String string // use the first field's data type
  Valid  bool
}

type User struct {
  Name NullString // data type will be string
}
```

### <span id="gorm_valuer_interface">GormValuerInterface</span>

GORM provides a `GormValuerInterface` interface, which can allow to create/update from SQL Expr or value based on context, for example:

```go
// GORM Valuer interface
type GormValuerInterface interface {
  GormValue(ctx context.Context, db *gorm.DB) clause.Expr
}
```

#### Create/Update from SQL Expr

```go
type Location struct {
    X, Y int
}

func (loc Location) GormDataType() string {
  return "geometry"
}

func (loc Location) GormValue(ctx context.Context, db *gorm.DB) clause.Expr {
  return clause.Expr{
    SQL:  "ST_PointFromText(?)",
    Vars: []interface{}{fmt.Sprintf("POINT(%d %d)", loc.X, loc.Y)},
  }
}

// Scan implements the sql.Scanner interface
func (loc *Location) Scan(v interface{}) error {
  // Scan a value into struct from database driver
}

type User struct {
  ID       int
  Name     string
  Location Location
}

db.Create(&User{
  Name:     "jinzhu",
  Location: Location{X: 100, Y: 100},
})
// INSERT INTO `users` (`name`,`point`) VALUES ("jinzhu",ST_PointFromText("POINT(100 100)"))

db.Model(&User{ID: 1}).Updates(User{
  Name:  "jinzhu",
  Location: Location{X: 100, Y: 100},
})
// UPDATE `user_with_points` SET `name`="jinzhu",`location`=ST_PointFromText("POINT(100 100)") WHERE `id` = 1
```

You can also create/update with SQL Expr from map, checkout [Create From SQL Expr](create.html#create_from_sql_expr) and [Update with SQL Expression](update.html#update_from_sql_expr) for details

#### Value based on Context

If you want to create or update a value depends on current context, you can also implements the `GormValuerInterface` interface, for example:

```go
type EncryptedString struct {
  Value string
}

func (es EncryptedString) GormValue(ctx context.Context, db *gorm.DB) (expr clause.Expr) {
  if encryptionKey, ok := ctx.Value("TenantEncryptionKey").(string); ok {
    return clause.Expr{SQL: "?", Vars: []interface{}{Encrypt(es.Value, encryptionKey)}}
  } else {
    db.AddError(errors.New("invalid encryption key"))
  }

  return
}
```

### Clause Expression

If you want to build some query helpers, you can make a struct that implements the `clause.Expression` interface:

```go
type Expression interface {
    Build(builder Builder)
}
```

Checkout [JSON](https://github.com/go-gorm/datatypes/blob/master/json.go) and [SQL Builder](sql_builder.html#clauses) for details, the following is an example of usage:

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
