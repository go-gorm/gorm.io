---
title: Migración
layout: página
---

## Migración Automática

Migra automáticamente tu esquema, para mantenerlo actualizado hasta la fecha.

**ADVERTENCIA:** AutoMigrate **SOLAMENTE** creará tablas, columnas faltantes e índices faltantes, y **NO** cambiará el tipo de columna existente o eliminará columnas no utilizadas para proteger sus datos.

```go
db.AutoMigrate(&User{})

db.AutoMigrate(&User{}, &Product{}, &Order{})

// Add table suffix when create tables
db.Set("gorm:table_options", "ENGINE=InnoDB").AutoMigrate(&User{})
```

## Otras Herramientas de Migración

El AutoMigrate de GORM funciona bien para la mayoría de los casos, pero si está buscando herramientas de migración más serias, GORM proporciona una interfaz DB genérica que podría ser útil para ti.

```go
// returns `*sql.DB`
db.DB()
```

Ir a [Interfaz Genérica](/docs/generic_interface.html) para más detalles.

## Schema Methods

### Has Table

```go
// Check model `User`'s table exists or not
db.HasTable(&User{})

// Check table `users` exists or not
db.HasTable("users")
```

### Create Table

```go
// Create table for model `User`
db.CreateTable(&User{})

// will append "ENGINE=InnoDB" to the SQL statement when creating table `users`
db.Set("gorm:table_options", "ENGINE=InnoDB").CreateTable(&User{})
```

### Drop table

```go
// Drop model `User`'s table
db.DropTable(&User{})

// Drop table `users`
db.DropTable("users")

// Drop model's `User`'s table and table `products`
db.DropTableIfExists(&User{}, "products")
```

### ModifyColumn

Modify column's type to given value

```go
// change column description's data type to `text` for model `User`
db.Model(&User{}).ModifyColumn("description", "text")
```

### DropColumn

```go
// Drop column description from model `User`
db.Model(&User{}).DropColumn("description")
```

### Add Indexes

```go
// Add index for columns `name` with given name `idx_user_name`
db.Model(&User{}).AddIndex("idx_user_name", "name")

// Add index for columns `name`, `age` with given name `idx_user_name_age`
db.Model(&User{}).AddIndex("idx_user_name_age", "name", "age")

// Add unique index
db.Model(&User{}).AddUniqueIndex("idx_user_name", "name")

// Add unique index for multiple columns
db.Model(&User{}).AddUniqueIndex("idx_user_name_age", "name", "age")
```

### Remove Index

```go
// Remove index
db.Model(&User{}).RemoveIndex("idx_user_name")
```

### Add Foreign Key

```go
// Add foreign key
// 1st param : foreignkey field
// 2nd param : destination table(id)
// 3rd param : ONDELETE
// 4th param : ONUPDATE
db.Model(&User{}).AddForeignKey("city_id", "cities(id)", "RESTRICT", "RESTRICT")
```

### Remove ForeignKey

```go
db.Model(&User{}).RemoveForeignKey("city_id", "cities(id)")
```