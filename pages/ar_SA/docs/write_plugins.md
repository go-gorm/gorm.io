---
title: Write Plugins
layout: page
---

## Callbacks

GORM itself is powered by `Callbacks`, it has callbacks for `Create`, `Query`, `Update`, `Delete`, `Row`, `Raw`, you could fully customize GORM with them as you want

Callbacks are registered into the global `*gorm.DB`, not the session-level, if you require `*gorm.DB` with different callbacks, you need to initialize another `*gorm.DB`

### Register Callback

Register a callback into callbacks

```go
func cropImage(db *gorm.DB) {
  if db.Statement.Schema != nil {
    // crop image fields and upload them to CDN, dummy code
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
    // processing
  }
}

db.Callback().Create().Register("crop_image", cropImage)
// register a callback for Create process
```

### Delete Callback

Delete a callback from callbacks

```go
db. After("gorm:create"). Query(). After("gorm:query"). Register("my_plugin:after_query", afterQuery)
db. Delete(). After("gorm:delete").
```

### Replace Callback

Replace a callback having the same name with the new one

```go
db. Callback(). Create(). Replace("gorm:create", newCreateFunction)
// replace callback `gorm:create` with new function `newCreateFunction` for Create process
```

### Register Callback with orders

Register callbacks with orders

```go
db. After("gorm:create"). Query(). After("gorm:query"). Register("my_plugin:after_query", afterQuery)
db. Delete(). After("gorm:delete"). Register("my_plugin:after_delete", afterDelete)
db. Update(). Before("gorm:update"). Register("my_plugin:before_update", beforeUpdate)
db. After("gorm:before_create"). Register("my_plugin:before_create", beforeCreate)
```

### Defined Callbacks

GORM has defined [some callbacks](https://github.com/go-gorm/gorm/blob/master/callbacks/callbacks.go) to support current GORM features, check them out before starting your plugins

## Plugin

GORM provides `Use` method to register plugins, the plugin needs to implement the `Plugin` interface

```go
type Plugin interface {
  Name() string
  Initialize(*gorm.DB) error
}
```

The `Initialize` method will be invoked when registering the plugin into GORM first time, and GORM will save the registered plugins, access them like:

```go
db. Config. Plugins[pluginName]
```

Checkout [Prometheus](prometheus.html) as example
