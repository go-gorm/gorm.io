---
title: 创建
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

**注意** 所有字段的零值, 比如 `0`, `''`, `false` 或者其它 [零值](https://tour.golang.org/basics/12)，都不会保存到数据库内，但会使用他们的默认值。 如果你想避免这种情况，可以考虑使用指针或实现 Scanner/Valuer 接口，比如：

```go
// 使用指针
type User struct {
  gorm.Model
  Name string
  Age  *int `gorm:"default:18"`
}

// 使用 Scanner/Valuer
type User struct {
  gorm.Model
  Name string
  Age  sql.NullInt64 `gorm:"default:18"`  // sql.NullInt64 实现了Scanner/Valuer接口
}
```

## 在Hooks中设置字段值

如果你想在`BeforeCreate` hook 中修改字段的值，可以使用`scope.SetColumn`，例如：

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