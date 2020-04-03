---
title: Create
layout: page
---

## Kayıt Oluştur

```go
user := User{Name: "Jinzhu", Age: 18, Birthday: time.Now()}

db.NewRecord(user) // => returns `true` as primary key is blank

db.Create(&user)

db.NewRecord(user) // => return `false` after `user` created
```

## Varsayılan Değerler

Etiket (golang tags) kullanarak bir alan için varsayılan değer tanımlayabilirsin. Örneğin:

```go
type Animal struct {
  ID   int64
  Name string `gorm:"default:'galeone'"`
  Age  int64
}
```

Bir değere sahip olmayan veya [başlangıç değerlerine (zero values)](https://tour.golang.org/basics/12) sahip olan alanlar, ekleme işlemi için oluşturulacak olan SQL'e katılmazlar. Veritabanında yeni bir kayıt oluşturulduktan sonra, Gorm bu alanları veritabanındaki değerleriyle günceller.

```go
var animal = Animal{Age: 99, Name: ""}
db.Create(&animal)
// INSERT INTO animals("age") values('99');
// SELECT name from animals WHERE ID=111; // the returning primary key is 111
// animal.Name => 'galeone'
```

**NOT:** başlangıç değerlerine (`0`, `''`, `false` ya da [ diğerleri ](https://tour.golang.org/basics/12)) sahip olan alanlar veritabanına kaydedilmez. Bu durumu önlemek istiyorsan, işaretçi (pointer) ya da scanner/valuer (bkz: sql.NullString) gibi tipleri kullanabilirsin:

```go
// işaretçi (pointer) tipini kullanan bir örnek
type User struct {
  gorm.Model
  Name string
  Age  *int `gorm:"default:18"`
}

// scanner/valuer tipini kullanan bir örnek
type User struct {
  gorm.Model
  Name string
  Age  sql.NullInt64 `gorm:"default:18"`
}
```

## Hook Kullanarak Bir Alanın Değerini Belirleme

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