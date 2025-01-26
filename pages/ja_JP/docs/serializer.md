---
title: シリアライザー
layout: page
---

シリアライザーは拡張可能なインターフェイスで、データベースでデータを直列化および並列化する方法をカスタマイズできます。

GORMには標準でいくつかのシリアライザー `json`, `gob`, `unixtime` が備わっています。以下はシリアライザーの利用方法の簡単な例です。

```go
type User struct {
    Name        []byte                 `gorm:"serializer:json"`
    Roles       Roles                  `gorm:"serializer:json"`
    Contracts   map[string]interface{} `gorm:"serializer:json"`
    JobInfo     Job                    `gorm:"type:bytes;serializer:gob"`
    CreatedTime int64                  `gorm:"serializer:unixtime;type:time"` // store int as datetime into database
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

## シリアライザーの登録

シリアライザはデータを直列化および並列化する方法を実装する必要があります。そのため、次のインターフェースを実装する必要があります。

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

たとえば、デフォルトの `JSONSerializer` は以下のように実装されています。

```go
// JSONSerializer JSONのシリアライザー
type JSONSerializer struct {
}

// Scan は SerializerInterface インターフェイスを実装
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

// Value は SerializerInterface インターフェイスを実装
func (JSONSerializer) Value(ctx context.Context, field *Field, dst reflect.Value, fieldValue interface{}) (interface{}, error) {
    return json.Marshal(fieldValue)
}
```

その後、以下のコードで登録されています。

```go
schema.RegisterSerializer("json", JSONSerializer{})
```

シリアライザーの登録後、`serializer` タグで使用できます。例:

```go
type User struct {
    Name []byte `gorm:"serializer:json"`
}
```

## シリアライザー型のカスタマイズ

登録済みのシリアライザーはタグで使用できます。上記の `SerializerInterface` を実装するカスタム構造体を作成し、フィールド型として直接使用することもできます。 例:

```go
type EncryptedString string

// ctx: contains request-scoped values
// field: the field using the serializer, contains GORM settings, struct tags
// dst: current model value, `user` in the below example
// dbValue: current field's value in database
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

// ctx: contains request-scoped values
// field: the field using the serializer, contains GORM settings, struct tags
// dst: current model value, `user` in the below example
// fieldValue: current field's value of the dst
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
