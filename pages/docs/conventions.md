title: Conventions
---

## `gorm.Model` struct

Base model definition `gorm.Model`, including fields `ID`, `CreatedAt`, `UpdatedAt`, `DeletedAt`, you could embed it in your model, or only write those fields you want

```go
// Base Model's definition
type Model struct {
  ID        uint `gorm:"primary_key"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt *time.Time
}

// Add fields `ID`, `CreatedAt`, `UpdatedAt`, `DeletedAt`
type User struct {
  gorm.Model
  Name string
}

// Only need field `ID`, `CreatedAt`
type User struct {
  ID        uint
  CreatedAt time.Time
  Name      string
}
```

## Table name is the pluralized version of struct name

```go
type User struct {} // default table name is `users`

// set User's table name to be `profiles`
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

// Disable table name's pluralization globally
db.SingularTable(true) // if set this to true, `User`'s default table name will be `user`, table name setted with `TableName` won't be affected
```

## Change default tablenames

You can apply any rules on the default table name by defining the `DefaultTableNameHandler`

```go
gorm.DefaultTableNameHandler = func (db *gorm.DB, defaultTableName string) string  {
	return "prefix_" + defaultTableName;
}
```

## Column name is the snake case of field's name

```go
type User struct {
  ID uint             // column name will be `id`
  Name string         // column name will be `name`
  Birthday time.Time  // column name will be `birthday`
  CreatedAt time.Time // column name will be `created_at`
}

// Overriding Column Name
type Animal struct {
	AnimalId    int64     `gorm:"column:beast_id"`         // set column name to `beast_id`
	Birthday    time.Time `gorm:"column:day_of_the_beast"` // set column name to `day_of_the_beast`
	Age         int64     `gorm:"column:age_of_the_beast"` // set column name to `age_of_the_beast`
}
```

## Field `ID` as primary key

```go
type User struct {
  ID   uint  // field named `ID` will be the default primary field
  Name string
}

// Set a field to be primary field with tag `primary_key`
type Animal struct {
  AnimalId int64 `gorm:"primary_key"` // set AnimalId to be primary key
  Name     string
  Age      int64
}
```

## Field `CreatedAt` used to store record's created time

Create records having `CreatedAt` field will set it to current time.

```go
db.Create(&user) // will set `CreatedAt` to current time

// To change its value, you could use `Update`
db.Model(&user).Update("CreatedAt", time.Now())
```

## Use `UpdatedAt` used to store record's updated time

Save records having `UpdatedAt` field will set it to current time.

```go
// Whenever one or more `user` fields are edited using Save() or Update(), `UpdatedAt` will be set to current time
db.Save(&user) // will set `UpdatedAt` to current time
db.Model(&user).Update("name", "jinzhu") // will set `UpdatedAt` to current time
```

## Use `DeletedAt` to store record's deleted time if field exists

Delete records having `DeletedAt` field, it won't be deleted from database, but only set field `DeletedAt`'s value to current time, and the record is not findable when querying, refer [Soft Delete](crud.html#soft-delete)
