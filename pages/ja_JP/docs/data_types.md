---
title: データ型のカスタマイズ
layout: page
---

GORMで使用できる独自のデータ型をユーザ自身で定義できるようにするために、GORMにはいくつかのインターフェースが用意されています。[json](https://github.com/go-gorm/datatypes/blob/master/json.go) を例として参照してみるとよいでしょう。

## 独自のデータ型を実装する

### Scanner / Valuer

独自のデータ型を使用するためには、[Scanner](https://pkg.go.dev/database/sql#Scanner) と [Valuer](https://pkg.go.dev/database/sql/driver#Valuer) インターフェイスを実装する必要があります。これらのインターフェイスを実装することで、DBからの値の取得処理やDBへの保存処理をGORMが行うことが可能になります。

例：

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

多くのサードパーティ製パッケージが `Scanner`/`Valuer` インターフェイスを実装しており、それらはGORMと併用することができます。例：

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

GORMはカラムのデータ型を `type` [tag](models.html#tags) から読み取ります。タグが指定されていない場合は、`GormDBDataTypeInterface` か `GormDataTypeInterface` が実装されているかをチェックします。インターフェイスが実装されている場合は、インターフェイスのメソッドの結果をデータ型として使用します。

```go
type GormDataTypeInterface interface {
  GormDataType() string
}

type GormDBDataTypeInterface interface {
  GormDBDataType(*gorm.DB, *schema.Field) string
}
```

`GormDataType` メソッドの返却値は通常のデータ型として使用され、`schema.Field` の `DataType` からも取得できます。これは [プラグインを作成する](write_plugins.html) 際や [hooksを利用する](hooks.html) 際に役立ちます。例：

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

`GormDBDataType` は通常、マイグレーション時に使用しているドライバに適切なデータ型を返します。例：

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

構造体が `GormDBDataTypeInterface` や `GormDataTypeInterface` インターフェイスを実装していない場合、GORMはその構造体の一番最初のフィールドからデータ型を推測します。例えば以下の `NullString` では `string` がデータ型として使用されます。

```go
type NullString struct {
  String string // 最初のフィールドのデータ型を使用する
  Valid  bool
}

type User struct {
  Name NullString // データ型は string となる
}
```

### <span id="gorm_valuer_interface">GormValuerInterface</span>

GORMは `GormValuerInterface` インターフェイスを提供しています。これにより、SQL式での作成/更新やコンテキストに基づいた値での作成/更新を行うことができます。例：

```go
// GORM Valuer interface
type GormValuerInterface interface {
  GormValue(ctx context.Context, db *gorm.DB) clause.Expr
}
```

#### SQL Expr での作成/更新

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

マップを使用した SQL Expr でレコードを作成/更新することもできます。詳細については、 [SQL式/Context Valuer で作成する](create.html#create_from_sql_expr) および [SQL式で更新する](update.html#update_from_sql_expr) をチェックしてください。

#### コンテキストに基づく値

現在のコンテキストに基づいて値を作成または更新したい場合は、 `GormValuerInterface` インターフェイスを実装することで実現可能です。

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

クエリヘルパーを構築したい場合、`clause.Expression` インターフェイスを実装する構造体を作成することで実現することができます。

```go
type Expression interface {
    Build(builder Builder)
}
```

詳細については [JSON](https://github.com/go-gorm/datatypes/blob/master/json.go) と [SQL Builder](sql_builder.html#clauses) を確認してください。以下は使い方の例です：

```go
// clause.Expression を使用してSQLを生成する
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

## 独自データ型のコレクション

[https://github.com/go-gorm/datatypes](https://github.com/go-gorm/datatypes) のGithubリポジトリに独自データ型のコレクションを用意しています。プルリクエストを歓迎しています！
