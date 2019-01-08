---
title: Conventions
layout: page
---
## gorm.Model

`gorm.Model` is a basic GoLang struct which includes the following fields: `ID`, `CreatedAt`, `UpdatedAt`, `DeletedAt`.

It may be embeded into your model or you may build your own model without it.

```go
// Definición de gorm.Model type Model struct {   ID uint `gorm:"primary_key"`   CreatedAt time.Time   UpdatedAt time.Time   DeletedAt *time.Time } // Inyectar campos `ID`, `CreatedAt`, `UpdatedAt`, `DeletedAt` en el modelo `User` type User struct {   gorm.Model   Name string } // Declarando el modelo sin gorm.Model type User struct {   ID int   Name string }
```

## `ID` como Clave Primaria

GORM uses any field with the name `ID` as the table's primary key by default.

```go
type User struct {   ID string // el campo llamado `ID` se utilizará como campo primario por defecto   Name string } // Establecer campo `AnimalID` como campo primario type Animal struct {   AnimalID int64 `gorm:"primary_key"`   Name string   Age int64 }
```

## Nombre de la Tabla Pluralizada

Table name is the pluralized version of struct name.

```go
type User struct {} // el nombre de la tabla por defecto es `users` // Establecer el nombre de la tabla de Usuario para ser `profiles` func (User) TableName() string {   return "profiles" } func (u User) TableName() string {     if u.Role == "admin" {         return "admin_users"     } else {         return "users"     } } // Deshabilita la pluralización del nombre de la tabla, si se establece en verdadero, el nombre de la tabla `User` será `user` db.SingularTable(true)
```

### Especificando el Nombre de la Tabla

```go
// Crear la tabla `deleted_users` con la definición struct Usuario db.Table("deleted_users").CreateTable(&User{}) var deleted_users []User db.Table("deleted_users").Find(&deleted_users) //// SELECT * FROM deleted_users; db.Table("deleted_users").Where("name = ?", "jinzhu").Delete() //// DELETE FROM deleted_users WHERE name = 'jinzhu';
```

### Cambiar nombre de tablas predeterminados

You can apply any rules on the default table name by defining the `DefaultTableNameHandler`.

```go
gorm.DefaultTableNameHandler = func (db *gorm.DB, defaultTableName string) string {     return "prefix_" + defaultTableName; }
```

## Nombre de la Columna usando Snake Case

Column names will be the field's name is lower snake case.

```go
type User struct {   ID uint // el nombre de la columna es `id`   Name string // el nombre de la columna es `name`   Birthday time.Time // el nombre de la columna es `birthday`   CreatedAt time.Time // el nombre de la columna es `created_at` } // Sobreescribiendo el nombre de columna type Animal struct {     AnimalId int64 `gorm:"column:beast_id"` // establecer el nombre de la columna a `beast_id`     Birthday time.Time `gorm:"column:day_of_the_beast"` // establecer el nombre de la columna a `day_of_the_beast`     Age int64 `gorm:"column:age_of_the_beast"` // establecer el nombre de la columna a `age_of_the_beast` }
```

## Seguimiento de Marca de Tiempo

### CreatedAt

For models having a `CreatedAt` field, it will be set to the time when the record is first created.

```go
db.Create(&user) // se establecerá `CreatedAt` a la hora actual // Para cambiar su valor, puede usar `Update` db.Model(&user).Update("CreatedAt", time.Now())
```

### UpdatedAt

For models having an `UpdatedAt` field, it will be set to time when the record is updated.

```go
db.Save(&user) // se establecerá `UpdatedAt` a la hora actual db.Model(&user).Update("name", "jinzhu") // se establecerá `UpdatedAt` a la hora actual
```

### DeletedAt

For models with a `DeletedAt` field, when `Delete` is called on that instance, it won't truly be deleted from database, but will set its `DeletedAt` field to the current time. Refer to [Soft Delete](/docs/delete.html#Soft-Delete)