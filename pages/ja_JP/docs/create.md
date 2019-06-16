---
title: Create
layout: page
---

## Create Record

```go
user := User{Name: "Jinzhu", Age: 18, Birthday: time.Now()}

db.NewRecord(user) // => 主キー画からの場合に `true` を返します。

db.Create(&user)

db.NewRecord(user) // => `user` が作られた後に `false` を返します。
```

## Default Values

以下のように、タグを利用してデフォルト値を設定できます。

```go
type Animal struct {
    ID   int64
    Name string `gorm:"default:'galeone'"`
    Age  int64
}
```

値のないフィールドや[ゼロ値](https://tour.golang.org/basics/12)のフィールドは、insertのSQL実行時には除外して実行されます。 After inserting the record into the database, gorm will load those fields' value from the database.

```go
var animal = Animal{Age: 99, Name: ""}
db.Create(&animal)
// INSERT INTO animals("age") values('99');
// SELECT name from animals WHERE ID=111; // the returning primary key is 111
// animal.Name => 'galeone'
```

**NOTE** all fields having a zero value, like `0`, `''`, `false` or other [zero values](https://tour.golang.org/basics/12), won't be saved into the database but will use its default value. If you want to avoid this, consider using a pointer type or scanner/valuer, e.g:

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

If you want to update a field's value in `BeforeCreate` hook, you can use `scope.SetColumn`, for example:

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