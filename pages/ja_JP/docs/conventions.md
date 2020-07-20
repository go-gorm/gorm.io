---
title: 規約
layout: page
---

## 主キーとしての`ID`

GORMはデフォルトで、テーブルの主キーとして `ID` という名前のフィールドを使用します。

```go
type User struct {
  ID   string //フィールドはデフォルトでは `ID` という名前のフィールドがプライマリフィールドとして使われます。
  Name string
}
```

他のフィールドを `primaryKey` タグで主キーとして設定できます

```go
// `AnimalID`フィールドをプライマリフィールドとして設定します
type Animal struct {
  ID     int64
  UUID   string `gorm:"primaryKey"`
  Name   string
  Age    int64
}
```

[複合プライマリキー](composite_primary_key.html) もチェックしてください

## テーブル名は複数形

GORM pluralizes struct name to `snake_cases` as table name, for struct `User`, its table name is `users` by convention

### TableName

You can change the default table name by implementing the `Tabler` interface, for example:

```go
type Tabler interface {
    TableName() string
}

// TableName overrides the table name used by User to `profiles`
func (User) TableName() string {
  return "profiles"
}
```

### Temporarily specify a name

Temporarily specify table name with `Table` method, for example:

```go
// Create table `deleted_users` with struct User's fields
db.Table("deleted_users").AutoMigrate(&User{})

// Query data from another table
var deletedUsers []User
db.Table("deleted_users").Find(&deletedUsers)
// SELECT * FROM deleted_users;

db.Table("deleted_users").Where("name = ?", "jinzhu").Delete(&User{})
// DELETE FROM deleted_users WHERE name = 'jinzhu';
```

Check out [From SubQuery](advanced_query.html#from_subquery) for how to use SubQuery in FROM clause

### <span id="naming_strategy">NamingStrategy</span>

GORM allows users change the default naming conventions by overriding the default `NamingStrategy`, which is used to build `TableName`, `ColumnName`, `JoinTableName`, `RelationshipFKName`, `CheckerName`, `IndexName`, Check out [GORM Config](gorm_config.html) for details

## カラム名

Column db name uses the field's name's `snake_case` by convention.

```go
type User struct {
  ID        uint      // column name is `id`
  Name      string    // column name is `name`
  Birthday  time.Time // column name is `birthday`
  CreatedAt time.Time // column name is `created_at`
}
```

You can override the column name with tag `column`, or use [`NamingStrategy`](#naming_strategy)

```go
type Animal struct {
  AnimalID int64     `gorm:"column:beast_id"`         // set name to `beast_id`
  Birthday time.Time `gorm:"column:day_of_the_beast"` // set name to `day_of_the_beast`
  Age      int64     `gorm:"column:age_of_the_beast"` // set name to `age_of_the_beast`
}
```

## タイムスタンプの追跡

### CreatedAt

For models having `CreatedAt` field, the field will be set to the current time when the record is first created if its value is zero

```go
db.Create(&user) // set `CreatedAt` to current time

// To change its value, you could use `Update`
db.Model(&user).Update("CreatedAt", time.Now())
```

### UpdatedAt

For models having `UpdatedAt` field, the field will be set to the current time when the record is updated or created if its value is zero

```go
db.Save(&user) // set `UpdatedAt` to current time

db.Model(&user).Update("name", "jinzhu") // will set `UpdatedAt` to current time
```

**NOTE** GORM supports having multiple time tracking fields, track with other fields or track with UNIX second/UNIX nanosecond, check [Models](models.html#time_tracking) for more details
