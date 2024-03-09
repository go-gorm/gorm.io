---
title: Сериализатор
layout: page
---

Serializer is an extensible interface that allows to customize how to serialize and deserialize data with database.

GORM предоставляет несколько сериализаторов по умолчанию: `json`, `gob`, `unixtime`, вот краткий пример того, как их использовать.

```go
type User struct {
    Name        []byte                 `gorm:"serializer:json"`
    Roles       Roles                  `gorm:"serializer:json"`
    Contracts   map[string]interface{} `gorm:"serializer:json"`
    JobInfo     Job                    `gorm:"type:bytes;serializer:gob"`
    CreatedTime int64                  `gorm:"serializer:unixtime;type:time"` // сохранить int как datetime в базе данных
}

type Roles []string

type Job struct {
    Title    string
    Location string
    IsIntern bool
}

createdAt := time.Date(2020, 1, 1, 0, 8, 0, 0, time.UTC)
data := User{
  Name:        []byte("jinzhu"),
  Roles:       []string{"admin", "owner"},
  Contracts:   map[string]interface{}{"name": "jinzhu", "age": 10},
  CreatedTime: createdAt.Unix(),
  JobInfo: Job{
    Title:    "Developer",
    Location: "NY",
    IsIntern: false,
  },
}

DB.Create(&data)
// INSERT INTO `users` (`name`,`roles`,`contracts`,`job_info`,`created_time`) VALUES
//   ("\"amluemh1\"","[\"admin\",\"owner\"]","{\"age\":10,\"name\":\"jinzhu\"}",<gob binary>,"2020-01-01 00:08:00")

var result User
DB.First(&result, "id = ?", data.ID)
// result => User{
//   Name:        []byte("jinzhu"),
//   Roles:       []string{"admin", "owner"},
//   Contracts:   map[string]interface{}{"name": "jinzhu", "age": 10},
//   CreatedTime: createdAt.Unix(),
//   JobInfo: Job{
//     Title:    "Developer",
//     Location: "NY",
//     IsIntern: false,
//   },
// }

DB.Where(User{Name: []byte("jinzhu")}).Take(&result)
// SELECT * FROM `users` WHERE `users`.`name` = "\"amluemh1\"
```

## Регистрация сериализатора

Сериализатор должен реализовать способ сериализации и десериализации данных, поэтому ему требуется реализовать следующий интерфейс

```go
import "gorm.io/gorm/schema"

type SerializerInterface interface {
    Scan(ctx context.Context, field *schema.Field, dst reflect.Value, dbValue interface{}) error
    SerializerValuerInterface
}

type SerializerValuerInterface interface {
    Value(ctx context.Context, field *schema.Field, dst reflect.Value, fieldValue interface{}) (interface{}, error)
}
```

Например, по умолчанию `JsonSerializer` реализован следующим образом:

```go
// JSONSerializer json serializer
type JSONSerializer struct {
}

// Scan реализует интерфейс сериализатора
func (JSONSerializer) Scan(ctx context.Context, field *Field, dst reflect.Value, dbValue interface{}) (err error) {
    fieldValue := reflect.New(field.FieldType)

    if dbValue != nil {
        var bytes []byte
        switch v := dbValue.(type) {
        case []byte:
            bytes = v
        case string:
            bytes = []byte(v)
        default:
            return fmt.Errorf("failed to unmarshal JSONB value: %#v", dbValue)
        }

        err = json.Unmarshal(bytes, fieldValue.Interface())
    }

    field.ReflectValueOf(ctx, dst).Set(fieldValue.Elem())
    return
}

// Value реализует интерфейс сериализатора
func (JSONSerializer) Value(ctx context.Context, field *Field, dst reflect.Value, fieldValue interface{}) (interface{}, error) {
    return json.Marshal(fieldValue)
}
```

И регистрируем следующим кодом:

```go
schema.RegisterSerializer("json", JSONSerializer{})
```

После регистрации сериализатора вы можете использовать его с тегом `serializer`, например:

```go
type User struct {
    Name []byte `gorm:"serializer:json"`
}
```

## Настраиваемый тип сериализатора

Вы можете использовать зарегистрированный сериализатор с тегами, вам также разрешено создавать настраиваемую структуру, которая реализует вышеуказанный `SerializerInterface` и напрямую использовать его в качестве типа поля, например:

```go
type EncryptedString string

// ctx: содержит значения, относящиеся к области запроса
// field: поле, использующее сериализатор, содержит настройки GORM, теги структуры
// dst: текущее значение модели, `user` в приведенном ниже примере
// dbValue: текущее значение поля в базе данных
func (es *EncryptedString) Scan(ctx context.Context, field *schema.Field, dst reflect.Value, dbValue interface{}) (err error) {
    switch value := dbValue.(type) {
    case []byte:
        *es = EncryptedString(bytes.TrimPrefix(value, []byte("hello")))
    case string:
        *es = EncryptedString(strings.TrimPrefix(value, "hello"))
    default:
        return fmt.Errorf("unsupported data %#v", dbValue)
    }
    return nil
}

// ctx: содержит значения, относящиеся к области запроса
// field: поле, использующее сериализатор, содержит настройки GORM, теги структуры
// dst: текущее значение модели, `user` в приведенном ниже примере
// fieldValue: текущее значение поля dst
func (es EncryptedString) Value(ctx context.Context, field *schema.Field, dst reflect.Value, fieldValue interface{}) (interface{}, error) {
    return "hello" + string(es), nil
}

type User struct {
    gorm.Model
    Password EncryptedString
}

data := User{
    Password: EncryptedString("pass"),
}

DB.Create(&data)
// INSERT INTO `serializer_structs` (`password`) VALUES ("hellopass")

var result User
DB.First(&result, "id = ?", data.ID)
// result => User{
//   Password: EncryptedString("pass"),
// }

DB.Where(User{Password: EncryptedString("pass")}).Take(&result)
// SELECT * FROM `users` WHERE `users`.`password` = "hellopass"
```
