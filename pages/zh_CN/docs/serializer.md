---
title: 序列化
layout: 页面
---

Serializer 是一个可扩展的接口，允许自定义如何使用数据库对数据进行序列化和反序列化

GORM 提供了一些默认的序列化器：json、gob、unixtime，这里有一个如何使用它的快速示例

```go
type User struct {
    Name        []byte                 `gorm:"serializer:json"`
    Roles       Roles                  `gorm:"serializer:json"`
    Contracts   map[string]interface{} `gorm:"serializer:json"`
    JobInfo     Job                    `gorm:"type:bytes;serializer:gob"`
    CreatedTime int64                  `gorm:"serializer:unixtime;type:time"` // 将 int 作为日期时间存储到数据库中
}

type Roles []string

type Job struct {
    Title    string
    Location string
    IsIntern bool
}
```

## 注册序列号器

一个Serializer需要实现如何对数据进行序列化和反序列化，所以需要实现如下接口

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

例如，默认 JSONSerializer 的实现如下：

```go
// JSONSerializer json序列化器
type JSONSerializer struct {
}

// 实现 Scan 方法
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

// 实现 Value 方法
func (JSONSerializer) Value(ctx context.Context, field *Field, dst reflect.Value, fieldValue interface{}) (interface{}, error) {
    return json.Marshal(fieldValue)
}
```

并使用以下代码注册：

```go
schema.RegisterSerializer("json", JSONSerializer{})
```

注册序列化器后，您可以将其与 `serializer` 标签一起使用，例如：

```go
type User struct {
    Name []byte `gorm:"serializer:json"`
}
```

## 自定义序列化器类型

You can use a registered serializer with tags, you are also allowed to create a customized struct that implements the above `SerializerInterface` and use it as a field type directly, for example:

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
