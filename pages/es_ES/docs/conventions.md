---
title: Conventions
layout: page
---
## gorm.Model

`gorm.Model` es una estructura que incluye algunos campos básicos, que incluyen los campos `ID`, `CreatedAt`, `UpdateAt`, `DeletedAt`.

Puede estar integrado en su modelo o construir su propio modelo sin él.

```go
// Definición de gorm.Model type Model struct {   ID uint `gorm:"primary_key"`   CreatedAt time.Time   UpdatedAt time.Time   DeletedAt *time.Time } // Inyectar campos `ID`, `CreatedAt`, `UpdatedAt`, `DeletedAt` en el modelo `User` type User struct {   gorm.Model   Name string } // Declarando el modelo sin gorm.Model type User struct {   ID int   Name string }
```

## `ID` como Clave Primaria

GORM usa el campo con el nombre `ID` como clave principal por defecto.

```go
type User struct {   ID string // el campo llamado `ID` se utilizará como campo primario por defecto   Name string } // Establecer campo `AnimalID` como campo primario type Animal struct {   AnimalID int64 `gorm:"primary_key"`   Name string   Age int64 }
```

## Nombre de la Tabla Pluralizada

El nombre de la tabla es la versión pluralizada del nombre de la estructura

```go
type User struct {} // el nombre de la tabla por defecto es `users` // Establecer el nombre de la tabla de Usuario para ser `profiles` func (User) TableName() string {   return "profiles" } func (u User) TableName() string {     if u.Role == "admin" {         return "admin_users"     } else {         return "users"     } } // Deshabilita la pluralización del nombre de la tabla, si se establece en verdadero, el nombre de la tabla `User` será `user` db.SingularTable(true)
```

### Especificando el Nombre de la Tabla

```go
// Crear la tabla `deleted_users` con la definición struct Usuario db.Table("deleted_users").CreateTable(&User{}) var deleted_users []User db.Table("deleted_users").Find(&deleted_users) //// SELECT * FROM deleted_users; db.Table("deleted_users").Where("name = ?", "jinzhu").Delete() //// DELETE FROM deleted_users WHERE name = 'jinzhu';
```

### Cambiar nombre de tablas predeterminados

Puede aplicar cualquier regla sobre el nombre predeterminado de la tabla definiendo el `DefaultTableNameHandler`

```go
gorm.DefaultTableNameHandler = func (db *gorm.DB, defaultTableName string) string {     return "prefix_" + defaultTableName; }
```

## Nombre de la Columna usando Snake Case

El nombre de la columna será el nombre del campo usando snake case en minúscula

```go
type User struct {   ID uint // el nombre de la columna es `id`   Name string // el nombre de la columna es `name`   Birthday time.Time // el nombre de la columna es `birthday`   CreatedAt time.Time // el nombre de la columna es `created_at` } // Sobreescribiendo el nombre de columna type Animal struct {     AnimalId int64 `gorm:"column:beast_id"` // establecer el nombre de la columna a `beast_id`     Birthday time.Time `gorm:"column:day_of_the_beast"` // establecer el nombre de la columna a `day_of_the_beast`     Age int64 `gorm:"column:age_of_the_beast"` // establecer el nombre de la columna a `age_of_the_beast` }
```

## Seguimiento de Marca de Tiempo

### CreatedAt

Para los modelos que tienen el campo `CreatedAt`, se establecerá en la hora actual cuando se cree un registro por primera vez.

```go
db.Create(&user) // se establecerá `CreatedAt` a la hora actual // Para cambiar su valor, puede usar `Update` db.Model(&user).Update("CreatedAt", time.Now())
```

### UpdatedAt

Para los modelos que tienen el campo `UpdateAt`, se establecerá en la hora actual cuando se actualice un registro.

```go
db.Save(&user) // se establecerá `UpdatedAt` a la hora actual db.Model(&user).Update("name", "jinzhu") // se establecerá `UpdatedAt` a la hora actual
```

### DeletedAt

Para los modelos que tienen el campo `UpdateAt`, cuando se eliminen sus instancias, no se eliminarán de la base de datos, sino que establecerán su campo `DeletedAt` en la hora actual, consulte [Soft Delete](/docs/delete.html#Soft-Delete)