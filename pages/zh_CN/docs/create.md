---
title: Create
layout: page
---
## 创建记录

```go
user := User{Name: "Jinzhu", Age: 18, Birthday: time.Now()}

db.NewRecord(user) // => 主键为空返回`true`

db.Create(&user)

db.NewRecord(user) // => 创建`user`后返回`false`
```

## 默认值

您可以使用tag来定义字段的默认值，例如：

```go
type Animal struct {
    ID   int64
    Name string `gorm:"default:'galeone'"`
    Age  int64
}
```

Then the inserting SQL will exclude those fields that don't have value or having [zero values](https://tour.golang.org/basics/12), after insert the record into database, gorm will load those fields's value from database.

```go
var animal = Animal{Age: 99, Name: ""}
db.Create(&animal)
// INSERT INTO animals("age") values('99');
// SELECT name from animals WHERE ID=111; // 返回主键为 111
// animal.Name => 'galeone'
```

**NOTE** all fields having zero value, like `0`, `''`, `false` or other [zero values](https://tour.golang.org/basics/12) won't be saved into database but will use its default value, it you want to avoid this, consider to use pointer type or scanner/valuer, e.g:

```go
// Use pointer value
type User struct {
  gorm.Model
  Name string
  Age  *int `gorm:"default:18"`
}

// Use scanner/valuer
type User struct {
  gorm.Model
  Name string
  Age  sql.NullInt64 `gorm:"default:18"`
}
```

## 在Hooks中设置字段值

如果要在`BeforeCreate`回调中设置字段的值，可以使用`scope.SetColumn`，例如：

```go
func (user *User) BeforeCreate(scope *gorm.Scope) error {
  scope.SetColumn("ID", uuid.New())
  return nil
}
```

## 扩展创建选项

```go
// 为Instert语句添加扩展SQL选项
db.Set("gorm:insert_option", "ON CONFLICT").Create(&product)
// INSERT INTO products (name, code) VALUES ("name", "code") ON CONFLICT;
```