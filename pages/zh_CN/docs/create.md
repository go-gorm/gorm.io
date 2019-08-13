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

你可以通过 tag 定义字段的默认值，比如：

```go
type Animal struct {
    ID   int64
    Name string `gorm:"default:'galeone'"`
    Age  int64
}
```

生成的 SQL 语句会排除没有值或值为 [零值](https://tour.golang.org/basics/12) 的字段。 将记录插入到数据库后，Gorm会从数据库加载那些字段的值。

```go
var animal = Animal{Age: 99, Name: ""}
db.Create(&animal)
// INSERT INTO animals("age") values('99');
// SELECT name from animals WHERE ID=111; // 返回主键为 111
// animal.Name => 'galeone'
```

**NOTE** all fields having a zero value, like `0`, `''`, `false` or other [zero values](https://tour.golang.org/basics/12), won't be saved into the database but will use its default value. If you want to avoid this, consider using a pointer type or scanner/valuer, e.g:

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

If you want to update a field's value in `BeforeCreate` hook, you can use `scope.SetColumn`, for example:

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