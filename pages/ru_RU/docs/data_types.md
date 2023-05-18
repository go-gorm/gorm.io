---
title: Настройка типов данных
layout: страница
---

GORM предоставляет некоторые интерфейсы, которые позволяют пользователям определять поддерживаемые типы данных для GORM, например [json](https://github.com/go-gorm/datatypes/blob/master/json.go)

## Реализация настраиваемого типа данных

### Scanner / Valuer

Настраиваемый тип данных должен реализовывать интерфейсы [Scanner](https://pkg.go.dev/database/sql#Scanner) и [Valuer](https://pkg.go.dev/database/sql/driver#Valuer), чтобы GORM знал, как получить/сохранить его в базе данных

Например:

```go
type JSON json.RawMessage

// Сканировать массив в Jsonb, описывает интерфейс sql.Scanner
func (j *JSON) Scan(value interface{}) error {
  bytes, ok := value.([]byte)
  if !ok {
    return errors.New(fmt.Sprint("Ошибка распаковки значения JSONB:", value))
  }

  result := json.RawMessage{}
  err := json.Unmarshal(bytes, &result)
  *j = JSON(result)
  return err
}

// Возвращает значение json, описывает интерфейс driver.Valuer
func (j JSON) Value() (driver.Value, error) {
  if len(j) == 0 {
    return nil, nil
  }
  return json.RawMessage(j).MarshalJSON()
}
```

Существует много сторонних пакетов реализующих интерфейсы `Scanner`/`Valuer`, которые могут использоваться вместе с GORM, например:

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

### Интерфейс GormDataTypeInterface

GORM будет считывать тип столбца базы данных из [тега](models.html#tags) `type`, если он не найден, проверит, реализует ли структура интерфейс `GormDBDataTypeInterface` или `GormDataTypeInterface` и будет использовать его результат в качестве типа данных

```go
type GormDataTypeInterface interface {
  GormDataType() string
}

type GormDBDataTypeInterface interface {
  GormDBDataType(*gorm.DB, *schema.Field) string
}
```

Результат `GormDataType` будет использован в качестве общего типа данных и может быть получен из поля `DataType` типа `schema.Field`, что может быть полезно при [написании плагинов](write_plugins.html) или [хуков](hooks.html), например:

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
    // что-то делаем
  }
}
```

`GormDBDataType` обычно возвращает правильный тип данных для текущего драйвера при миграции, например:

```go
func (JSON) GormDBDataType(db *gorm.DB, field *schema.Field) string {
  // ипсользуйте field.Tag, field.TagSettings для получения тегов полей
  // смотрите все возможности https://github.com/go-gorm/gorm/blob/master/schema/field.go

  // возвращает другой тип базы данных в зависимости от имени драйвера
  switch db.Dialector.Name() {
  case "mysql", "sqlite":
    return "JSON"
  case "postgres":
    return "JSONB"
  }
  return ""
}
```

Если в struct не реализует интерфейс `GormDBDataTypeInterface` или `GormDataTypeInterface`, GORM возьмет тип данных из первого поля struct, например, будет использовать `string` для `NullString`

```go
type NullString struct {
  String string // использует тип данных первого поля
  Valid  bool
}

type User struct {
  Name NullString // тип будет string
}
```

### <span id="gorm_valuer_interface">Интерфейс GormValuerInterface</span>

GORM предоставляет интерфейс `GormValuerInterface`, который может позволить создавать/ обновлять из SQL-выражения или значения на основе контекста, например:

```go
// GORM Valuer интерфейс
type GormValuerInterface interface {
  GormValue(ctx context.Context, db *gorm.DB) clause.Expr
}
```

#### Создание/Обновление из SQL-выражения

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

// Scan реализует интерфейс sql.Scanner
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

Вы также можете создать / обновить с помощью SQL-выражения из map, смотрите [Создать из SQL-выражения](create.html#create_from_sql_expr) и [Обновить с помощью SQL-выражения](update.html#update_from_sql_expr) для получения подробной информации

#### Значение на основе контекста

Если вы хотите создать или обновить значение в зависимости от текущего контекста, вы также можете реализовать интерфейс `GormValuerInterface`, например:

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

Если вы хотите собрать несколько помощников запросов, вы можете создать struct, который реализует интерфейс `clause.Expression`:

```go
type Expression interface {
    Build(builder Builder)
}
```

Смотрите [JSON](https://github.com/go-gorm/datatypes/blob/master/json.go) и [SQL Builder](sql_builder.html#clauses) для получения подробной информации, ниже приведен пример использования:

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

## Настраиваемые наборы типов данных

We created a Github repo for customized data types collections [https://github.com/go-gorm/datatypes](https://github.com/go-gorm/datatypes), pull request welcome ;)
