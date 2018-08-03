---
title: Create
layout: page
---

## Create Record

```go
user := User{Name: "Jinzhu", Age: 18, Birthday: time.Now()}

db.NewRecord(user) // => returns `true` as primary key is blank

db.Create(&user)

db.NewRecord(user) // => return `false` after `user` created
```

## Default Values

You could define field's default value with tag, for example:

```go
type Animal struct {
	ID   int64
	Name string `gorm:"default:'galeone'"`
	Age  int64
}
```

Then the inserting SQL will exclude those fields that don't have value or having [zero values](https://tour.golang.org/basics/12), after insert the record into database, gorm will load those fields's value from database.

```go
var animal = Animal{Age: 99, Name: ""}
db.Create(&animal)
// INSERT INTO animals("age") values('99');
// SELECT name from animals WHERE ID=111; // the returning primary key is 111
// animal.Name => 'galeone'
```

**NOTE** all fields having zero value, like `0`, `''`, `false` or other [zero values](https://tour.golang.org/basics/12) won't be saved into database but will use its default value, if you want to avoid this, consider to use pointer type or scanner/valuer, e.g:

```go
// Use pointer value
type User struct {
  gorm.Model
  Name string
  Age  *int `gorm:"default:18"`
}

// Use scanner/valuer
type User struct {
  gorm.Model
  Name string
  Age  sql.NullInt64 `gorm:"default:18"`
}
```

## Setting Field Values In Hooks

If you want to update field's value in `BeforeCreate` hook, you could use `scope.SetColumn`, for example:

```go
func (user *User) BeforeCreate(scope *gorm.Scope) error {
  scope.SetColumn("ID", uuid.New())
  return nil
}
```

## Extra Creating option

```go
// Add extra SQL option for inserting SQL
db.Set("gorm:insert_option", "ON CONFLICT").Create(&product)
// INSERT INTO products (name, code) VALUES ("name", "code") ON CONFLICT;
```
