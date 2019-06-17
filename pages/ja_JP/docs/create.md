---
title: Create
layout: page
---

## Create Record

```go
user := User{Name: "Jinzhu", Age: 18, Birthday: time.Now()}

db.NewRecord(user) // => 主キーが空の場合に `true` を返します。

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

値のないフィールドや[ゼロ値](https://tour.golang.org/basics/12)のフィールドは、insertのSQL実行時には除外して実行されます。 gormは、これらのフィールドをデータベースへレコードの挿入後に読み込みます。

```go
var animal = Animal{Age: 99, Name: ""}
db.Create(&animal)
// INSERT INTO animals("age") values('99');
// SELECT name from animals WHERE ID=111; // 返却された主キーは111です。
// animal.Name => 'galeone'
```

**NOTE** `0`, `''`, `false` その他の [ゼロ値](https://tour.golang.org/basics/12)は、 データベースに保存されず、代わりにデフォルト値が設定されます。 これを回避したい場合には、以下のようにポインタか`scanner/valuer`を利用してください。

```go
// ポインタを利用する場合
type User struct {
  gorm.Model
  Name string
  Age  *int `gorm:"default:18"`
}

// scanner/valuerを利用する場合
type User struct {
  gorm.Model
  Name string
  Age  sql.NullInt64 `gorm:"default:18"`
}
```

## Setting Field Values In Hooks

`BeforeCreate` フックでフィールドの値を更新したい場合、`scope.SetColumn`が利用できます。

```go
func (user *User) BeforeCreate(scope *gorm.Scope) error {
  scope.SetColumn("ID", uuid.New())
  return nil
}
```

## Extra Creating option

```go
// InsertのSQLに、オプションを設定できます。
db.Set("gorm:insert_option", "ON CONFLICT").Create(&product)
// INSERT INTO products (name, code) VALUES ("name", "code") ON CONFLICT;
```