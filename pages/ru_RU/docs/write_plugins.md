---
title: Написание плагинов
layout: страница
---

Сам GORM работает на `Callbacks`, чтобы вы могли полностью настроить GORM как вы хотите

## Зарегистрировать новый callback

Зарегистрировать новый callback в callback

```go
func updateCreated(scope *Scope) {
    if scope.HasColumn("Created") {
        scope.SetColumn("Created", NowFunc())
    }
}

db.Callback().Create().Register("update_created_at", updateCreated)
// регистрация callback для Create процесса
```

## Удалить существующий callback

Удалить callback из callback

```go
db.Callback().Create().Remove("gorm:create")
// удаляет callback `gorm:create` из Create callbacks
```

## Заменить существующий callback

Заменить callback с таким же именем на новый

```go
db.Callback().Create().Replace("gorm:create", newCreateFunction)
// заменяет callback `gorm:create` на новую функцию `newCreateFunction` для Create процесса
```

## Регистрация очереди callback

Регистрация callback с очередью

```go
db.Callback().Create().Before("gorm:create").Register("update_created_at", updateCreated)
db.Callback().Create().After("gorm:create").Register("update_created_at", updateCreated)
db.Callback().Query().After("gorm:query").Register("my_plugin:after_query", afterQuery)
db.Callback().Delete().After("gorm:delete").Register("my_plugin:after_delete", afterDelete)
db.Callback().Update().Before("gorm:update").Register("my_plugin:before_update", beforeUpdate)
db.Callback().Create().Before("gorm:create").After("gorm:before_create").Register("my_plugin:before_create", beforeCreate)
```

## Предустановленные callbacks

GORM имеет установленные callback для реализации CRUD операций, проверьте их названия перед созданием своих плагинов

- [Create callbacks](https://github.com/jinzhu/gorm/blob/master/callback_create.go)

- [Update callbacks](https://github.com/jinzhu/gorm/blob/master/callback_update.go)

- [Query callbacks](https://github.com/jinzhu/gorm/blob/master/callback_query.go)

- [Delete callbacks](https://github.com/jinzhu/gorm/blob/master/callback_delete.go)

- Row Query callbacks - no callbacks registered by default

Callback Row Query будет вызываться когда используется `Row` или `Rows`, по умолчанию нет никаких коллбэков, Вы должны зарегистрировать свою например так:

```go
func updateTableName(scope *gorm.Scope) {
  scope.Search.Table(scope.TableName() + "_draft") // append `_draft` to table name
}

db.Callback().RowQuery().Register("publish:update_table_name", updateTableName)
```

Просмотрите <https://godoc.org/github.com/jinzhu/gorm> для просмотра всех доступных API