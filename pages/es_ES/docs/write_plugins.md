---
title: Escribir Plugins
layout: page
---

GORM está respaldado por `Callbacks`, así que puede editar GORM completamente como lo desee

## Registrar un nuevo callback

Registrar un callback en callbaks

```go
func updateCreated(scope *Scope) {
    if scope.HasColumn("Created") {
        scope.SetColumn("Created", NowFunc())
    }
}

db.Callback().Create().Register("update_created_at", updateCreated)
// register a callback for Create process
```

## Eliminar un callback existente

Eliminar un callback de callbaks

```go
db.Callback().Create().Remove("gorm:create")
// delete callback `gorm:create` from Create callbacks
```

## Reemplazar un callback existente

Reemplazar un callback con uno nuevo del mismo nombre

```go
db.Callback().Create().Replace("gorm:create", newCreateFunction)
// replace callback `gorm:create` with new function `newCreateFunction` for Create process
```

## Registrar órdenes de callback

Register callbacks with orders

```go
db.Callback().Create().Before("gorm:create").Register("update_created_at", updateCreated)
db.Callback().Create().After("gorm:create").Register("update_created_at", updateCreated)
db.Callback().Query().After("gorm:query").Register("my_plugin:after_query", afterQuery)
db.Callback().Delete().After("gorm:delete").Register("my_plugin:after_delete", afterDelete)
db.Callback().Update().Before("gorm:update").Register("my_plugin:before_update", beforeUpdate)
db.Callback().Create().Before("gorm:create").After("gorm:before_create").Register("my_plugin:before_create", beforeCreate)
```

## Callbacks Predefinidos

GORM tiene callbacks definidos para realizar operaciones CRUD, revíselos antes de escribir sus plugins

- [Crear callbacks](https://github.com/jinzhu/gorm/blob/master/callback_create.go)

- [Actualizar callbacks](https://github.com/jinzhu/gorm/blob/master/callback_update.go)

- [Query callbacks](https://github.com/jinzhu/gorm/blob/master/callback_query.go)

- [Eliminar callbacks](https://github.com/jinzhu/gorm/blob/master/callback_delete.go)

- Row Query callbacks - no callbacks registered by default

Row Query callbacks will be called when perform `Row` or `Rows`, there are no registered callbacks by default, you could register a new one like:

```go
func updateTableName(scope *gorm.Scope) {
  scope.Search.Table(scope.TableName() + "_draft") // append `_draft` to table name
}

db.Callback().RowQuery().Register("publish:update_table_name", updateTableName)
```

View <https://godoc.org/github.com/jinzhu/gorm> to view all available API
