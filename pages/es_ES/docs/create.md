---
title: Create
layout: page
---

## Crear un Registro

```go
user := User{Name: "Jinzhu", Age: 18, Birthday: time.Now()} db.NewRecord(user) // => retorna `true` como clave primaria en blanco db.Create(&user) db.NewRecord(user) // => retorna `false` después de crear `user`
```

## Valores por Defecto

You can define a field's default value with a tag. For example:

```go
type Animal struct {
    ID   int64
    Name string `gorm:"default:'galeone'"`
    Age  int64
}
```

Then the inserting SQL will exclude those fields that have no value or [zero values](https://tour.golang.org/basics/12). After inserting the record into the database, gorm will load those fields' value from the database.

```go
var animal = Animal{Age: 99, Name: ""} db.Create(&animal) // INSERT INTO animals("age") values('99'); // SELECT name from animals WHERE ID=111; // el retorno de la clave primaria es 111 // animal.Name => 'galeone'
```

**NOTE** all fields having a zero value, like `0`, `''`, `false` or other [zero values](https://tour.golang.org/basics/12), won't be saved into the database but will use its default value. If you want to avoid this, consider using a pointer type or scanner/valuer, e.g:

```go
// Usar valor de puntero type User struct {   gorm.Model   Name string   Age *int `gorm:"default:18"` } // Usar scanner/valuer type User struct {   gorm.Model   Name string   Age sql.NullInt64 `gorm:"default:18"` }
```

## Setting Field Values In Hooks

If you want to update a field's value in `BeforeCreate` hook, you can use `scope.SetColumn`, for example:

```go
func (user *User) BeforeCreate(scope *gorm.Scope) error {
  scope.SetColumn("ID", uuid.New())
  return nil
}
```

## Opción de Creación Adicional

```go
// Agregar una opción SQL adicional para insertar SQL db.Set("gorm:insert_option", "ON CONFLICT").Create(&product) // INSERT INTO products (name, code) VALUES ("name", "code") ON CONFLICT;
```
