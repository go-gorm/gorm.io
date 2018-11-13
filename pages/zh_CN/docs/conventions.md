---
title: 约定
layout: page
---
## gorm.Model

`gorm.Model ` 是一个包含了基本字段的结构（struct）, 其中包括字段： `ID`、`CreatedAt`、`UpdatedAt`、`DeletedAt` 。

它可以嵌入到您的模型中, 也可以不用它来构建您自己的模型。

```go
// gorm.Model definition
type Model struct {
  ID        uint `gorm:"primary_key"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt *time.Time
}

// Inject fields `ID`, `CreatedAt`, `UpdatedAt`, `DeletedAt` into model `User`
type User struct {
  gorm.Model
  Name string
}

// Declaring model w/o gorm.Model
type User struct {
  ID   int
  Name string
}
```

## `ID` 作为主键

默认情况下, gorm 使用名称为 `ID` 的字段作为主键。

```go
type User struct {
  ID   string // field named `ID` will be used as primary field by default
  Name string
}

// Set field `AnimalID` as primary field
type Animal struct {
  AnimalID int64 `gorm:"primary_key"`
  Name     string
  Age      int64
}
```

## 多元化的表名（Table Name）

Table name is the pluralized version of struct name

```go
type User struct {} // default table name is `users`

// Set User's table name to be `profiles`
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
db.SingularTable(true)
```

### 指定表名称

```go
// Create `deleted_users` table with struct User's definition
db.Table("deleted_users").CreateTable(&User{})

var deleted_users []User
db.Table("deleted_users").Find(&deleted_users)
//// SELECT * FROM deleted_users;

db.Table("deleted_users").Where("name = ?", "jinzhu").Delete()
//// DELETE FROM deleted_users WHERE name = 'jinzhu';
```

### 更改默认表名称（table name）

您可以通过定义 `DefaultTableNameHandler` 对默认表名应用任何规则

```go
gorm.DefaultTableNameHandler = func (db *gorm.DB, defaultTableName string) string  {
    return "prefix_" + defaultTableName;
}
```

## 下划线分割命名（Snake Case）的列名

列名将是小写下划线命名的字段名称

```go
type User struct {
  ID        uint      // column name is `id`
  Name      string    // column name is `name`
  Birthday  time.Time // column name is `birthday`
  CreatedAt time.Time // column name is `created_at`
}

// Overriding Column Name
type Animal struct {
    AnimalId    int64     `gorm:"column:beast_id"`         // set column name to `beast_id`
    Birthday    time.Time `gorm:"column:day_of_the_beast"` // set column name to `day_of_the_beast`
    Age         int64     `gorm:"column:age_of_the_beast"` // set column name to `age_of_the_beast`
}
```

## 时间点（Timestamp）跟踪

### CreatedAt

对于具有 `CreatedAt` 字段的模型，当记录被首次创建时，它将被设置为当前时间。

```go
db.Create(&user) // will set `CreatedAt` to current time

// To change its value, you could use `Update`
db.Model(&user).Update("CreatedAt", time.Now())
```

### UpdatedAt

对于具有 `UpdateAt` 字段的模型，当记录被更新时，它将被设置为当前时间。

```go
db.Save(&user) // will set `UpdatedAt` to current time

db.Model(&user).Update("name", "jinzhu") // will set `UpdatedAt` to current time
```

### DeletedAt

对于具有 `DeletedAt` 字段的模型, 当删除其实例时, 不会从数据库中删除它们, 而是将其 `DeletedAt` 字段设置为当前时间, 请参阅 [Soft delete](/docs/delete.html#Soft-Delete)