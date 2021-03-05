---
title: 自定义数据类型
layout: page
---

GORM 提供了少量接口，使用户能够为 GORM 定义支持的数据类型，这里以 [json](https://github.com/go-gorm/datatypes/blob/master/json.go) 为例

## 实现自定义数据类型

### Scanner / Valuer

自定义的数据类型必须实现 [Scanner](https://pkg.go.dev/database/sql#Scanner) 和 [Valuer](https://pkg.go.dev/database/sql/driver#Valuer) 接口，以便让 GORM 知道如何将该类型接收、保存到数据库

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

有许多第三方包实现了 `Scanner`/`Valuer` 接口，可与 GORM 一起使用，例如：

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

GORM 会从 `type` [标签](models.html#tags) 中读取字段的数据库类型，如果找不到，则会检查该结构体是否实现了 `GormDBDataTypeInterface` 或 `GormDataTypeInterface` 接口，然后使用接口返回值作为数据类型

```go
type GormDataTypeInterface interface {
  GormDataType() string
}

type GormDBDataTypeInterface interface {
  GormDBDataType(*gorm.DB, *schema.Field) string
}
```

`GormDataType` 的结果用于生成通用数据类型，也可以通过 `schema.Field` 的 `DataType` 字段得到。这在 [编写插件](write_plugins.html) 或者 [hook](hooks.html) 时可能会有用，例如：

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
    // 做点什么...
  }
}
```

在迁移时，`GormDBDataType` 通常会为当前驱动返回恰当的数据类型，例如：

```go
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

如果 struct 没有实现 `GormDBDataTypeInterface` 或 `GormDataTypeInterface` 接口，GORM 会根据 struct 第一个字段推测其数据类型，例如：会为 `NullString` 使用 `string`

```go
type NullString struct {
  String string // 使用第一个字段的数据类型
  Valid  bool
}

type User struct {
  Name NullString // 数据类型会是 string
}
```

### <span id="gorm_valuer_interface">GormValuerInterface</span>

GORM 提供了 `GormValuerInterface` 接口，支持使用 SQL 表达式或基于 context 的值进行 create/update，例如：

```go
// GORM Valuer interface
type GormValuerInterface interface {
  GormValue(ctx context.Context, db *gorm.DB) clause.Expr
}
```

#### 使用 SQL 表达式进行 Create/Update

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

// Scan 方法实现了 sql.Scanner 接口
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

你也可以根据 SQL 表达式进行 create/update，查看 [Create From SQL Expr](create.html#create_from_sql_expr) 和 [Update with SQL Expression](update.html#update_from_sql_expr) 获取详情

#### 基于 Context 的值

如果你想创建或更新一个依赖于当前 context 的值，你也可以实现 `GormValuerInterface` 接口，例如：

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

### 条件表达式

如果你想构建一些查询 helper，你可以让 struct 实现 `clause.Expression` 接口：

```go
type Expression interface {
    Build(builder Builder)
}
```

查看 [JSON](https://github.com/go-gorm/datatypes/blob/master/json.go) 和 [SQL Builder](sql_builder.html#clauses) 获取详情，下面是一个示例：

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
