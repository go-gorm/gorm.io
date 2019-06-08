---
title: 约定
layout: page
---

## gorm.Model

`gorm.Model` 是一个包含了`ID`, `CreatedAt`, `UpdatedAt`, `DeletedAt`四个字段的GoLang结构体。

你可以将它嵌入到你自己的模型中，当然你也可以完全使用自己的模型。

```go
// gorm.Model 定义
type Model struct {
  ID        uint `gorm:"primary_key"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt *time.Time
}

// Inject fields `ID`, `CreatedAt`, `UpdatedAt`, `DeletedAt` into model `User`
// 将 `ID`, `CreatedAt`, `UpdatedAt`, `DeletedAt`字段注入到`User`模型中
type User struct {
  gorm.Model
  Name string
}

// 不使用gorm.Model定义模型
type User struct {
  ID   int
  Name string
}
```

## `ID` 作为主键

GORM 默认会使用名为`ID`的字段作为表的主键。

```go
type User struct {
  ID   string // 名为`ID`的字段会默认作为表的主键
  Name string
}

// 使用`AnimalID`作为主键
type Animal struct {
  AnimalID int64 `gorm:"primary_key"`
  Name     string
  Age      int64
}
```

## 表名（Table Name）

表名默认就是结构体名称的复数，例如：

```go
type User struct {} // 默认表名为 `users`

// 通过TableName方法将User表命名为`profiles`
func (User) TableName() string {
  return "profiles"
}

func (u User) TableName() string {
    if u.Role == "admin" {
        return "admin_users"
    } else {
        return "users"
    }
}

// Disable table name's pluralization, if set to true, `User`'s table name will be `user`
// 关闭复数表名，如果设置为true，`User`表的表名就会是`user`，而不是`users`
db.SingularTable(true)
```

### 指定表名称

```go
// 使用User结构体创建名为`deleted_users`的表
db.Table("deleted_users").CreateTable(&User{})

var deleted_users []User
db.Table("deleted_users").Find(&deleted_users)
//// SELECT * FROM deleted_users;

db.Table("deleted_users").Where("name = ?", "jinzhu").Delete()
//// DELETE FROM deleted_users WHERE name = 'jinzhu';
```

### 更改默认表名称（table name）

你可以通过定义`DefaultTableNameHandler`来设置默认表名的命名规则

```go
gorm.DefaultTableNameHandler = func (db *gorm.DB, defaultTableName string) string  {
    return "prefix_" + defaultTableName;
}
```

## 下划线分割命名（Snake Case）的列名

列名由字段名称进行下划线分割来生成

```go
type User struct {
  ID        uint      // column name is `id`
  Name      string    // column name is `name`
  Birthday  time.Time // column name is `birthday`
  CreatedAt time.Time // column name is `created_at`
}

// 重写列名
type Animal struct {
    AnimalId    int64     `gorm:"column:beast_id"`         // 设置列名为 `beast_id`
    Birthday    time.Time `gorm:"column:day_of_the_beast"` // 设置列名为 `day_of_the_beast`
    Age         int64     `gorm:"column:age_of_the_beast"` //设置列名为 `age_of_the_beast`
}
```

## 时间点（Timestamp）跟踪

### CreatedAt

For models having a `CreatedAt` field, it will be set to the time when the record is first created.

```go
db.Create(&user) // will set `CreatedAt` to current time

// To change its value, you could use `Update`
db.Model(&user).Update("CreatedAt", time.Now())
```

### UpdatedAt

For models having an `UpdatedAt` field, it will be set to time when the record is updated.

```go
db.Save(&user) // will set `UpdatedAt` to current time

db.Model(&user).Update("name", "jinzhu") // will set `UpdatedAt` to current time
```

### DeletedAt

For models with a `DeletedAt` field, when `Delete` is called on that instance, it won't truly be deleted from database, but will set its `DeletedAt` field to the current time. Refer to [Soft Delete](/docs/delete.html#Soft-Delete)