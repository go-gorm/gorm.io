---
title: Write Plugins
layout: page
---

GORM itself is powered by `Callbacks`, so you could fully customize GORM as you want

## Register a new callback

Register a callback into callbacks

```go
func updateCreated(scope *Scope) {
    if scope.HasColumn("Created") {
        scope.SetColumn("Created", NowFunc())
    }
}

db.Callback().Create().Register("update_created_at", updateCreated)
// register a callback for Create process
```

## Delete an existing callback

Delete a callback from callbacks

```go
db.Callback().Create().Remove("gorm:create")
// delete callback `gorm:create` from Create callbacks
```

## Replace an existing callback

Ganti panggilan balik dengan nama yang sama dengan yang baru

```go
db.Callback().Create().Replace("gorm:create", newCreateFunction)
// replace callback `gorm:create` with new function `newCreateFunction` for Create process
```

## Register callback orders

Register callbacks with orders

```go
db.Callback().Create().Before("gorm:create").Register("update_created_at", updateCreated)
db.Callback().Create().After("gorm:create").Register("update_created_at", updateCreated)
db.Callback().Query().After("gorm:query").Register("my_plugin:after_query", afterQuery)
db.Callback().Delete().After("gorm:delete").Register("my_plugin:after_delete", afterDelete)
db.Callback().Update().Before("gorm:update").Register("my_plugin:before_update", beforeUpdate)
db.Callback().Create().Before("gorm:create").After("gorm:before_create").Register("my_plugin:before_create", beforeCreate)
```

## Pre-Defined Callbacks

GORM telah menolak panggilan balik untuk melakukan operasi CRUD, memeriksa mereka sebelum mulai menulis plugin Anda

- [Buat panggilanbalik](https://github.com/jinzhu/gorm/blob/master/callback_create.go)

- [Memperbarui panggilanbalik](https://github.com/jinzhu/gorm/blob/master/callback_update.go)

- [Query callbacks](https://github.com/jinzhu/gorm/blob/master/callback_query.go)

- [Menghapus panggilanbalik](https://github.com/jinzhu/gorm/blob/master/callback_delete.go)

- Row Query callbacks - no callbacks registered by default

Row Query callbacks will be called when perform `Row` or `Rows`, there are no registered callbacks by default, you could register a new one like:

```go
func updateTableName(scope *gorm.Scope) {
  scope.Search.Table(scope.TableName() + "_draft") // append `_draft` to table name
}

db.Callback().RowQuery().Register("publish:update_table_name", updateTableName)
```

View <https://godoc.org/github.com/jinzhu/gorm> to view all available API
