---
title: Generic database interface sql.DB
layout: page
---
GORM proporciona el método `DB` que devuelve la interfaz de base de datos genérica [*sql.DB](http://golang.org/pkg/database/sql/#DB) de la conexión actuall `*gorm.DB`

```go
// Obtenga el objeto de base de datos genérico sql.DB para usar sus funciones db.DB() // Ping db.DB().Ping()
```

**NOTA** Si la conexión de base de datos subyacente no es un `*sql.DB`, como en una transacción, devolverá null

## Agrupación de Conexiones

```go
// SetMaxIdleConns establece la cantidad máxima de conexiones en el grupo de conexiones inactivas.
db.DB().SetMaxIdleConns(10) // SetMaxOpenConns establece el número máximo de conexiones abiertas en la base de datos.
db.DB().SetMaxOpenConns(100) // SetConnMaxLifetime establece la cantidad máxima de tiempo que una conexión puede ser reutilizada.
db.DB().SetConnMaxLifetime(time.Hour)
```