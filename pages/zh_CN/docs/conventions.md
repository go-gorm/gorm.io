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
// 将 `UUID` 设为主键
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
**注意：** `TableName` 不支持动态变化，它会被缓存下来以便后续使用。想要使用动态表名，你可以使用 `Scopes`，例如：
{% endnote %}

```go
func UserTable(user User) func (tx *gorm.DB) *gorm.DB {
  return func (tx *gorm.DB) *gorm.DB {
    if user.Admin {
      return tx.Table("admin_users")
    }

    return tx.Table("users")
  }
}

db.Scopes(UserTable(user)).Create(&user)
```

### 临时指定表名

您可以使用 `Table` 方法临时指定表名，例如：

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

查看 [from 子查询](advanced_query.html#from_subquery) 了解如何在 FROM 子句中使用子查询

### <span id="naming_strategy">命名策略</span>

GORM 允许用户通过覆盖默认的`命名策略`更改默认的命名约定，命名策略被用于构建： `TableName`、`ColumnName`、`JoinTableName`、`RelationshipFKName`、`CheckerName`、`IndexName`。查看 [GORM 配置](gorm_config.html#naming_strategy) 获取详情

## 列名

根据约定，数据表的列名使用的是 struct 字段名的 `蛇形命名`

```go
type User struct {
  ID        uint      // 列名是 `id`
  Name      string    // 列名是 `name`
  Birthday  time.Time // 列名是 `birthday`
  CreatedAt time.Time // 列名是 `created_at`
}
```

您可以使用 `column` 标签或 [`命名策略`](#naming_strategy) 来覆盖列名

```go
type Animal struct {
  AnimalID int64     `gorm:"column:beast_id"`         // 将列名设为 `beast_id`
  Birthday time.Time `gorm:"column:day_of_the_beast"` // 将列名设为 `day_of_the_beast`
  Age      int64     `gorm:"column:age_of_the_beast"` // 将列名设为 `age_of_the_beast`
}
```

## 时间戳追踪

### CreatedAt

对于有 `CreatedAt` 字段的模型，创建记录时，如果该字段值为零值，则将该字段的值设为当前时间

```go
db.Create(&user) // 将 `CreatedAt` 设为当前时间

user2 := User{Name: "jinzhu", CreatedAt: time.Now()}
db.Create(&user2) // user2 的 `CreatedAt` 不会被修改

// 想要修改该值，您可以使用 `Update`
db.Model(&user).Update("CreatedAt", time.Now())
```

You can disable the timestamp tracking by setting `autoCreateTime` tag to `false`, for example:

```go
type User struct {
  CreatedAt time.Time `gorm:"autoCreateTime:false"`
}
```

### UpdatedAt

For models having `UpdatedAt` field, the field will be set to the current time when the record is updated or created if its value is zero

```go
db.Save(&user) // set `UpdatedAt` to current time

db.Model(&user).Update("name", "jinzhu") // will set `UpdatedAt` to current time

db.Model(&user).UpdateColumn("name", "jinzhu") // `UpdatedAt` won't be changed

user2 := User{Name: "jinzhu", UpdatedAt: time.Now()}
db.Create(&user2) // user2's `UpdatedAt` won't be changed when creating

user3 := User{Name: "jinzhu", UpdatedAt: time.Now()}
db.Save(&user3) // user3's `UpdatedAt` will change to current time when updating
```

You can disable the timestamp tracking by setting `autoUpdateTime` tag to `false`, for example:

```go
type User struct {
  UpdatedAt time.Time `gorm:"autoUpdateTime:false"`
}
```

{% note %}
**NOTE** GORM supports having multiple time tracking fields and track with UNIX (nano/milli) seconds, checkout [Models](models.html#time_tracking) for more details
{% endnote %}
