---
title: Konventionen
layout: page
---
## gorm.Model

`gorm.Model` ist ein Struct, welches einige grundlegende Felder enthält, einschließlich der Felder `ID`, `CreatedAt`, `UpdatedAt` und `DeletedAt`.

Diese können in dein Modell eingebunden werden oder du kannst dein eigenes Modell ohne sie bauen.

```go
// gorm.Model definition
type Model struct {
  ID        uint `gorm:"primary_key"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt *time.Time
}

// Injiziere die Felder `ID`, `CreatedAt`, `UpdatedAt`, `DeletedAt` in
// das Modell `User`
type User struct {
  gorm.Model
  Name string
}

// Deklariere ein Modell ohne gorm.Model
type User struct {
  ID   int
  Name string
}
```

## `ID` als Primärschlüssel

GORM benutzt standardmäßig das Feld mit den Name `ID` as Primärschlüssel.

```go
type User struct {
  ID   string //  `ID` wird standardmäßig als Primärschlüssel verwendet
  Name string
}

// Setze das Feld `AnimalID` als Primärschlüssel
type Animal struct {
  AnimalID int64 `gorm:"primary_key"`
  Name     string
  Age      int64
}
```

## Pluralisierte Tabellennamen

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

### Specifying The Table Name

```go
// Create `deleted_users` table with struct User's definition
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