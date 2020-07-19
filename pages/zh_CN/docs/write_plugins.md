---
title: 编写插件
layout: page
---

## Callbacks

GORM 自身也是基于 `Callbacks` 的，包括 `Create`、`Query`、`Update`、`Delete`、`Row`、`Raw`。此外，您也完全可以根据自己的意愿自定义 GORM

回调会注册到全局 `*gorm.DB`，而不是会话级别。如果您想要 `*gorm.DB` 具有不同的回调，您需要初始化另一个 `*gorm.DB`

### 注册回调

注册回调至 callbacks

```go
func cropImage(db *gorm.DB) {
  if db.Statement.Schema != nil {
    // 裁剪图像字段并将其上传至 CDN 的伪代码
    for _, field := range db.Statement.Schema.Fields {
      switch db.Statement.ReflectValue.Kind() {
      case reflect.Slice, reflect.Array:
        for i := 0; i < db.Statement.ReflectValue.Len(); i++ {
          if fieldValue, isZero := field.ValueOf(db.Statement.ReflectValue.Index(i)); !isZero {
            if crop, ok := fieldValue.(CropInterface); ok {
              crop.Crop()
            }
          }
        }
      case reflect.Struct:
        if fieldValue, isZero := field.ValueOf(db.Statement.ReflectValue.Index(i)); isZero {
          if crop, ok := fieldValue.(CropInterface); ok {
            crop.Crop()
          }
        }
      }
    }

    field := db.Statement.Schema.LookUpField("Name")
    // 处理中...
  }
}

db.Callback().Create().Register("crop_image", cropImage)
// 为 Create 流程注册一个回调
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
db.Callback().Create().Before("gorm:create").Register("update_created_at", updateCreated)
db.Callback().Create().After("gorm:create").Register("update_created_at", updateCreated)
db.Callback().Query().After("gorm:query").Register("my_plugin:after_query", afterQuery)
db.Callback().Delete().After("gorm:delete").Register("my_plugin:after_delete", afterDelete)
db.Callback().Update().Before("gorm:update").Register("my_plugin:before_update", beforeUpdate)
db.Callback().Create().Before("gorm:create").After("gorm:before_create").Register("my_plugin:before_create", beforeCreate)
```

### 预定义回调

GORM 已经定义了 [一些回调](https://github.com/go-gorm/gorm/blob/master/callbacks/callbacks.go) 来支持当前的 GORM 功能，在启动您的插件之前可以先看看这些回调

## 插件

GORM 提供了 `Use` 方法来注册插件，插件需要实现 `Plugin` 接口

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
