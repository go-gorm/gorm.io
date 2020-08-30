---
title: 约定
layout: page
---

## 使用 `ID` 作为主键

默认情况下，GORM 会使用 `ID` 作为表的主键。

```go
type User struct {
  ID   string // 默认情况下，名为 `ID` 的字段会作为表的主键
  Name string
}
```

你可以通过标签 `primaryKey` 将其它字段设为主键

```go
// 将 `AnimalID` 设为主键
type Animal struct {
  ID     int64
  UUID   string `gorm:"primaryKey"`
  Name   string
  Age    int64
}
```

此外，您还可以看看 [复合主键](composite_primary_key.html)

## 复数表名

GORM 使用结构体名的 `蛇形命名` 作为表名。对于结构体 `User`，根据约定，其表名为 `users`

### TableName

您可以实现 `Tabler` 接口来更改默认表名，例如：

```go
type Tabler interface {
    TableName() string
}

// TableName 会将 User 的表名重写为 `profiles`
func (User) TableName() string {
  return "profiles"
}
```

{% note warn %}
**NOTE** `TableName` doesn't allow dynamic name, its result will be cached for future, to use dynamic name, you can use `Scopes`, for example:
{% endnote %}

```go
func UserTable(user User) func (db *gorm.DB) *gorm.DB {
  return func (db *gorm.DB) *gorm.DB {
    if user.Admin {
      return db.Table("admin_users")
    }

    return db.Table("users")
  }
}

DB.Scopes(UserTable(user)).Create(&user)
```

### 临时指定表明

Temporarily specify table name with `Table` method, for example:

```go
// 根据 User 的字段创建 `deleted_users` 表
db.Table("deleted_users").AutoMigrate(&User{})

// 从另一张表查询数据
var deletedUsers []User
db.Table("deleted_users").Find(&deletedUsers)
// SELECT * FROM deleted_users;

db.Table("deleted_users").Where("name = ?", "jinzhu").Delete(&User{})
// DELETE FROM deleted_users WHERE name = 'jinzhu';
```

Check out [From SubQuery](advanced_query.html#from_subquery) for how to use SubQuery in FROM clause

### <span id="naming_strategy">命名策略</span>

GORM allows users change the default naming conventions by overriding the default `NamingStrategy`, which is used to build `TableName`, `ColumnName`, `JoinTableName`, `RelationshipFKName`, `CheckerName`, `IndexName`, Check out [GORM Config](gorm_config.html#naming_strategy) for details

## 列名

Column db name uses the field's name's `snake_case` by convention.

```go
type User struct {
  ID        uint      // 列名是 `id`
  Name      string    // 列名是 `name`
  Birthday  time.Time // 列名是 `birthday`
  CreatedAt time.Time // 列名是 `created_at`
}
```

You can override the column name with tag `column` or use [`NamingStrategy`](#naming_strategy)

```go
type Animal struct {
  AnimalID int64     `gorm:"column:beast_id"`         // 将列名设为 `beast_id`
  Birthday time.Time `gorm:"column:day_of_the_beast"` // 将列名设为 `day_of_the_beast`
  Age      int64     `gorm:"column:age_of_the_beast"` // 将列名设为 `age_of_the_beast`
}
```

## 时间戳追踪

### CreatedAt

For models having `CreatedAt` field, the field will be set to the current time when the record is first created if its value is zero

```go
db.Create(&user) // 将 `CreatedAt` 设为当前时间

user2 := User{Name: "jinzhu", CreatedAt: time.Now()}
db.Create(&user2) // user2 的 `CreatedAt` 不会被修改

// 想要修改该值，您可以使用 `Update`
db.Model(&user).Update("CreatedAt", time.Now())
```

### UpdatedAt

For models having `UpdatedAt` field, the field will be set to the current time when the record is updated or created if its value is zero

```go
db.Save(&user) // 将 `UpdatedAt` 设为当前时间

db.Model(&user).Update("name", "jinzhu") // 会将 `UpdatedAt` 设为当前时间

db.Model(&user).UpdateColumn("name", "jinzhu") // `UpdatedAt` 不会被修改

user2 := User{Name: "jinzhu", UpdatedAt: time.Now()}
db.Create(&user2) // 创建记录时，user2 的 `UpdatedAt` 不会被修改

user3 := User{Name: "jinzhu", UpdatedAt: time.Now()}
db.Save(&user3) // 更新世，user3 的 `UpdatedAt` 会修改为当前时间
```

{% note %}
**NOTE** GORM supports having multiple time tracking fields and track with UNIX (nano/milli) seconds, checkout [Models](models.html#time_tracking) for more details
{% endnote %}
