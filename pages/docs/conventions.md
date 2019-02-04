---
title: Conventions
layout: page
---

## gorm.Model

`gorm.Model` is a basic GoLang struct which includes the following fields: `ID`, `CreatedAt`, `UpdatedAt`, `DeletedAt`.

It may be embeded into your model or you may build your own model without it.

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

## `ID` as Primary Key

GORM uses any field with the name `ID` as the table's primary key by default.

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

## Pluralized Table Name

Table name is the pluralized version of struct name.

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

You can apply any rules on the default table name by defining the `DefaultTableNameHandler`.

```go
gorm.DefaultTableNameHandler = func (db *gorm.DB, defaultTableName string) string  {
	return "prefix_" + defaultTableName;
}
```

## Snake Case Column Name

Column names will be the field's name is lower snake case.

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
