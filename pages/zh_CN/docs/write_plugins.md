---
title: 写插件
layout: page
---

GORM本身由`Callbacks`提供支持，因此您可以根据需要完全自定义GORM

## 注册新的callback

注册新的callback到callbacks中

```go
func updateCreated(scope *Scope) {
    if scope.HasColumn("Created") {
        scope.SetColumn("Created", NowFunc())
    }
}

db.Callback().Create().Register("update_created_at", updateCreated)
// 注册Create进程的回调
```

## 删除现有的callback

从callbacks中删除callback

```go
db.Callback().Create().Remove("gorm:create")
// 从Create回调中删除`gorm:create`回调
```

## 替换现有的callback

替换同名callback

```go
db.Callback().Create().Replace("gorm:create", newCreateFunction)
// 使用新函数`newCreateFunction`替换回调`gorm:create`用于创建过程
```

## 注册callback顺序

注册 callback 顺序

```go
db.Callback().Create().Before("gorm:create").Register("update_created_at", updateCreated)
db.Callback().Create().After("gorm:create").Register("update_created_at", updateCreated)
db.Callback().Query().After("gorm:query").Register("my_plugin:after_query", afterQuery)
db.Callback().Delete().After("gorm:delete").Register("my_plugin:after_delete", afterDelete)
db.Callback().Update().Before("gorm:update").Register("my_plugin:before_update", beforeUpdate)
db.Callback().Create().Before("gorm:create").After("gorm:before_create").Register("my_plugin:before_create", beforeCreate)
```

## 预定义回调

GORM定义了回调以执行其CRUD操作，在开始编写插件之前检查它们。

- [Create callbacks](https://github.com/jinzhu/gorm/blob/master/callback_create.go)

- [Update callbacks](https://github.com/jinzhu/gorm/blob/master/callback_update.go)

- [Query callbacks](https://github.com/jinzhu/gorm/blob/master/callback_query.go)

- [Delete callbacks](https://github.com/jinzhu/gorm/blob/master/callback_delete.go)

- Row Query callbacks - 没有默认注册的 callback

Row Query callbacks 在运行 `Row` 或 `Rows` 时被调用，默认情况下它没有注册的回调，你可以注册一个新的回调：

```go
func updateTableName(scope *gorm.Scope) {
  scope.Search.Table(scope.TableName() + "_draft") // 追加 `_draft` 到表名后
}

db.Callback().RowQuery().Register("publish:update_table_name", updateTableName)
```

查阅所有可用 [API](https://godoc.org/github.com/jinzhu/gorm)