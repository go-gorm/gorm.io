---
title: 慣例
layout: page
---
## gorm.Model

`gorm.Model`はいくつかの基本的なフィールドを持った構造体であり、`ID`、`CreatedAt`、`UpdatedAt`、`DeletedAt`を持っています。

`gorm.Model`をあなたのモデルに埋め込んだり、それを使わずに自分用のモデルを構築できます。

```go
// gorm.Modelの定義
type Model struct {
  ID        uint `gorm:"primary_key"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt *time.Time
}

// `ID`, `CreatedAt`, `UpdatedAt`, `DeletedAt`フィールドを`User`モデルに注入します
type User struct {
  gorm.Model
  Name string
}

// gorm.Model無しにモデルを宣言します
type User struct {
  ID   int
  Name string
}
```

## 主キーとしての`ID`

GORMはデフォルトで`ID`という名前のフィールドを主キーとして扱います

```go
type User struct {
  ID   string // `ID`という名前のフィールドはデフォルトで主キーとして扱われます
  Name string
}

// `AnimalID`フィールドを主キーに設定します
type Animal struct {
  AnimalID int64 `gorm:"primary_key"`
  Name     string
  Age      int64
}
```

## 複数形のテーブル名

テーブル名は構造体名の複数形になります

```go
type User struct {} // `デフォルトのテーブル名は`users`です

// Userのテーブル名を`profiles`に設定します
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

// テーブル名の複数形化を無効化します。trueにすると`User`のテーブル名は`user`になります
db.SingularTable(true)
```

### テーブル名の指定

```go
// User構造体の定義を使って`deleted_users`テーブルを作成します
db.Table("deleted_users").CreateTable(&User{})

var deleted_users []User
db.Table("deleted_users").Find(&deleted_users)
//// SELECT * FROM deleted_users;

db.Table("deleted_users").Where("name = ?", "jinzhu").Delete()
//// DELETE FROM deleted_users WHERE name = 'jinzhu';
```

### Change default tablenames

You can apply any rules on the default table name by defining the `DefaultTableNameHandler`

```go
gorm.DefaultTableNameHandler = func (db *gorm.DB, defaultTableName string) string  {
    return "prefix_" + defaultTableName;
}
```

## Snake Case Column Name

Column name will be the lower snake case field's name

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

## Timestamp Tracking

### CreatedAt

For models having `CreatedAt` field, it will be set to current time when record is first created.

```go
db.Create(&user) // will set `CreatedAt` to current time

// To change its value, you could use `Update`
db.Model(&user).Update("CreatedAt", time.Now())
```

### UpdatedAt

For models having `UpdatedAt` field, it will be set to current time when record is updated.

```go
db.Save(&user) // will set `UpdatedAt` to current time

db.Model(&user).Update("name", "jinzhu") // will set `UpdatedAt` to current time
```

### DeletedAt

For models having `UpdatedAt` field, when delete their instances, they won't be deleted from database, but will set its `DeletedAt` field to current time, refer [Soft Delete](/docs/delete.html#Soft-Delete)