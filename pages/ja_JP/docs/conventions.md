---
title: 規則
layout: page
---

## gorm.Model

`gorm.Model` is a basic GoLang struct which includes the following fields: `ID`, `CreatedAt`, `UpdatedAt`, `DeletedAt`.

It may be embeded into your model or you may build your own model without it.

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

GORM uses any field with the name `ID` as the table's primary key by default.

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

Table name is the pluralized version of struct name.

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

### デフォルトのテーブル名の変更

You can apply any rules on the default table name by defining the `DefaultTableNameHandler`.

```go
gorm.DefaultTableNameHandler = func (db *gorm.DB, defaultTableName string) string  {
    return "prefix_" + defaultTableName;
}
```

## スネークケースのカラム名

Column names will be the field's name is lower snake case.

```go
type User struct {
  ID        uint      // カラム名は`id`
  Name      string    // カラム名は`name`
  Birthday  time.Time // カラム名は`birthday`
  CreatedAt time.Time // カラム名は`created_at`
}

// カラム名の上書き
type Animal struct {
    AnimalId    int64     `gorm:"column:beast_id"`         // カラム名を`beast_id`に設定します
    Birthday    time.Time `gorm:"column:day_of_the_beast"` // カラム名を`day_of_the_beast`に設定します
    Age         int64     `gorm:"column:age_of_the_beast"` // カラム名を`age_of_the_beast`に設定します
}
```

## タイムスタンプの追跡

### CreatedAt

For models having a `CreatedAt` field, it will be set to the time when the record is first created.

```go
db.Create(&user) // `CreatedAt`には現在時刻が設定されます

// 値を変更するには`Update`を使います
db.Model(&user).Update("CreatedAt", time.Now())
```

### UpdatedAt

For models having an `UpdatedAt` field, it will be set to time when the record is updated.

```go
db.Save(&user) // `UpdatedAt`に現在時刻を設定します

db.Model(&user).Update("name", "jinzhu") // `UpdatedAt`に現在時刻を設定します
```

### DeletedAt

For models with a `DeletedAt` field, when `Delete` is called on that instance, it won't truly be deleted from database, but will set its `DeletedAt` field to the current time. Refer to [Soft Delete](/docs/delete.html#Soft-Delete)