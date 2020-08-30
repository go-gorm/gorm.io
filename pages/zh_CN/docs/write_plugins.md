---
title: 编写插件
layout: page
---

## Callbacks

GORM 自身也是基于 `Callbacks` 的，包括 `Create`、`Query`、`Update`、`Delete`、`Row`、`Raw`。此外，您也完全可以根据自己的意愿自定义 GORM

回调会注册到全局 `*gorm.DB`，而不是会话级别。如果您想要 `*gorm.DB` 具有不同的回调，您需要初始化另一个 `*gorm.DB`

### 注册 Callback

注册 callback 至 callbacks

```go
func cropImage(db *gorm.DB) {
  if db.Statement.Schema != nil {
    // 伪代码：裁剪图片并上传至 CDN
    for _, field := range db.Statement.Schema.Fields {
      switch db.Statement.ReflectValue.Kind() {
      case reflect.Slice, reflect.Array:
        for i := 0; i < db.Statement.ReflectValue.Len(); i++ {
          // 从字段获取值
          if fieldValue, isZero := field.ValueOf(db.Statement.ReflectValue.Index(i)); !isZero {
            if crop, ok := fieldValue.(CropInterface); ok {
              crop.Crop()
            }
          }
        }
      case reflect.Struct:
        // 从字段获取值
        if fieldValue, isZero := field.ValueOf(db.Statement.ReflectValue); isZero {
          if crop, ok := fieldValue.(CropInterface); ok {
            crop.Crop()
          }
        }

        // 设置字段值
        err := field.Set(db.Statement.ReflectValue, "newValue")
      }
    }

    // 当前 Model 的所有字段
    db.Statement.Schema.Fields

    // 当前 Model 的所有主键字段
    db.Statement.Schema.PrimaryFields

    // 优先主键字段：带有 db 名为 `id` 或定义的第一个主键字段。
    db.Statement.Schema.PrioritizedPrimaryField

    // 当前 Model 的所有关系
    db.Statement.Schema.Relationships

    // 根据 db 名或字段名查找字段
    field := db.Statement.Schema.LookUpField("Name")

    // 处理...
  }
}

db.Callback().Create().Register("crop_image", cropImage)
// 为 Create 流程注册一个 callback
```

### 删除回调

从 callbacks 中删除回调

```go
db.Callback().Create().Remove("gorm:create")
// 从 Create 的 callbacks 中删除 `gorm:create`
```

### 替换回调

用一个新的回调替换已有的同名回调

```go
db.Callback().Create().Replace("gorm:create", newCreateFunction)
// 用新函数 `newCreateFunction` 替换 Create 流程目前的 `gorm:create`
```

### 注册带顺序的回调

注册带顺序的回调

```go
// before gorm:create
db.Callback().Create().Before("gorm:create").Register("update_created_at", updateCreated)

// after gorm:create
db.Callback().Create().After("gorm:create").Register("update_created_at", updateCreated)

// before gorm:query
db.Callback().Query().After("gorm:query").Register("my_plugin:after_query", afterQuery)

// after gorm:delete
db.Callback().Delete().After("gorm:delete").Register("my_plugin:after_delete", afterDelete)

// before gorm:update
db.Callback().Update().Before("gorm:update").Register("my_plugin:before_update", beforeUpdate)

// before gorm:create and after gorm:before_create
db.Callback().Create().Before("gorm:create").After("gorm:before_create").Register("my_plugin:before_create", beforeCreate)

// before any other callbacks
db.Callback().Create().Before("*").Register("update_created_at", updateCreated)

// after any other callbacks
db.Callback().Create().After("*").Register("update_created_at", updateCreated)
```

### 预定义回调

GORM has defined [some callbacks](https://github.com/go-gorm/gorm/blob/master/callbacks/callbacks.go) to power current GORM features, check them out before starting your plugins

## 插件

GORM provides a `Use` method to register plugins, the plugin needs to implement the `Plugin` interface

```go
type Plugin interface {
  Name() string
  Initialize(*gorm.DB) error
}
```

当插件首次注册到 GORM 时将调用 `Initialize` 方法，且 GORM 会保存已注册的插件，你可以这样访问访问：

```go
db.Config.Plugins[pluginName]
```

查看 [Prometheus](prometheus.html) 的例子
