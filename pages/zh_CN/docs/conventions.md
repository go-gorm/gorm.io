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
  ID        uint      // 列名为`id`
  Name      string    // 列名为 `name`
  Birthday  time.Time // 列名为 `birthday`
  CreatedAt time.Time // 列名为 `created_at`
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

如果模型有 `CreatedAt`字段，该字段的值将会是初次创建记录的时间。

```go
db.Create(&user) // `CreatedAt`将会是当前时间

// 可以使用`Update`方法来改变`CreateAt`的值
db.Model(&user).Update("CreatedAt", time.Now())
```

### UpdatedAt

如果模型有`UpdatedAt`字段，该字段的值将会是每次更新记录的时间。

```go
db.Save(&user) // `UpdatedAt`将会是当前时间

db.Model(&user).Update("name", "jinzhu") // `UpdatedAt`将会是当前时间
```

### DeletedAt

如果模型有`DeletedAt`字段，调用`Delete`删除该记录时，将会设置`DeletedAt`字段为当前时间，而不是直接将记录从数据库中删除。 什么是 [软删除](/docs/delete.html#Soft-Delete)