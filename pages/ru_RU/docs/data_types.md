---
title: Типы данных
layout: страница
---

GORM предоставляет некоторые интерфейсы, которые позволяют пользователям определять поддерживаемые типы данных для GORM, например [json](https://github.com/go-gorm/datatypes/blob/master/json.go)

## Описание типов данных

### Scanner / Valuer

Настраиваемый тип данных должен реализовывать интерфейсы [Scanner](https://pkg.go.dev/database/sql/sql#Scanner) и [Valuer](https://pkg.go.dev/database/sql/driver#Valuer), чтобы GORM знал, как получить/сохранить его в базе данных

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

### Интерфейс GormDataTypeInterface

Настраиваемый тип данных может работать в различных типах баз данных, вы можете использовать `GormDataTypeInterface` для их установки, например:

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

### Настраиваемые исключения

Настраиваемый тип данных требует специфического SQL, который не может использовать текущий GORM API, вы можете определить `Builder` для реализации `clause.Expression (исключений)`

```go
type Expression interface {
    Build(builder Builder)
}
```

Смотрите [JSON](https://github.com/go-gorm/datatypes/blob/master/json.go) как пример реализации

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

Мы создали репозиторий Github для настраиваемых коллекций типов данных [https://github.com/go-gorm/datatypes](https://github.com/go-gorm/datatypes), запрос на слияние приветсвуется ;)
