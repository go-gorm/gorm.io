---
title: Konvensi
layout: page
---
## gorm.Model

`gorm.Model` is a struct including some basic fields, which including fields `ID`, `CreatedAt`, `UpdatedAt`, `DeletedAt`.

Itu bisa ditanam ke dalam model anda atau bangun model anda sendiri tanpa itu.

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

## `ID` sebagai Kunci Utama

GORM menggunakan bidang dengan nama `ID` sebagai kunci primer secara bawaan.

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

## Nama Tabel Pluralised

Nama tabel adalah versi jamak dari nama struct

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

### Menentukan nama tabel

```go
// Create `deleted_users` table with struct User's definition
db.Table("deleted_users").CreateTable(&User{})

var deleted_users []User
db.Table("deleted_users").Find(&deleted_users)
//// SELECT * FROM deleted_users;

db.Table("deleted_users").Where("name = ?", "jinzhu").Delete()
//// DELETE FROM deleted_users WHERE name = 'jinzhu';
```

### Ubah nama tabel bawaan

Anda dapat menerapkan aturan pada nama tabel bawaan dengan menetapkan `DefaultTableNameHandler`

```go
gorm.DefaultTableNameHandler = func (db *gorm.DB, defaultTableName string) string  {
    return "prefix_" + defaultTableName;
}
```

## Nama Kolom Kasus Ular

Nama kolom akan menjadi nama kotak ular yang lebih rendah

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

Untuk model yang memiliki field `UpdatedAt` saat menghapus instance mereka, mereka tidak akan dihapus dari database, namun akan mengatur bidang `DeletedAt` ke waktu sekarang, rujuk[Soft Delete](/docs/delete.html#Soft-Delete)