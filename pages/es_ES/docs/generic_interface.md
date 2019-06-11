---
title: Generic database interface sql.DB
layout: page
---

GORM provides the method `DB` which returns a generic database interface [*sql.DB](http://golang.org/pkg/database/sql/#DB) from the current `*gorm.DB` connection

```go
// Obtenga el objeto de base de datos genérico sql.DB para usar sus funciones db.DB() // Ping db.DB().Ping()
```

**NOTE** If the underlying database connection is not a `*sql.DB`, like in a transaction, it will returns `nil`

## Agrupación de Conexiones

```go
// SetMaxIdleConns establece la cantidad máxima de conexiones en el grupo de conexiones inactivas.
db.DB().SetMaxIdleConns(10) // SetMaxOpenConns establece el número máximo de conexiones abiertas en la base de datos.
db.DB().SetMaxOpenConns(100) // SetConnMaxLifetime establece la cantidad máxima de tiempo que una conexión puede ser reutilizada.
db.DB().SetConnMaxLifetime(time.Hour)
```
