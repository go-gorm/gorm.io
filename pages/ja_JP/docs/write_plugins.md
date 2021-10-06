---
title: Write Plugins
layout: page
---

## Callbacks

GORM内部では、 `Callbacks` の技術が活かされています。GORMには `Create`, `Query`, `Update`, `Delete`, `Row`, `Raw` 処理のcallbackが用意されています。これらのcallbackを使うことでGORMを自由にカスタマイズすることができます。

Callbacks はグローバルな `*gorm.DB` に登録されます（セッションレベルではありません）。そのため、別のcallbackが登録された `*gorm.DB` が必要な場合は、新規の `*gorm.DB` を用意する必要があります。

### Callbackを登録する

Register a callback into callbacks

```go
func cropImage(db *gorm.DB) {
  if db.Statement.Schema != nil {
    // crop image fields and upload them to CDN, dummy code
    for _, field := range db.Statement.Schema.Fields {
      switch db.Statement.ReflectValue.Kind() {
      case reflect.Slice, reflect.Array:
        for i := 0; i < db.Statement.ReflectValue.Len(); i++ {
          // Get value from field
          if fieldValue, isZero := field.ValueOf(db.Statement.ReflectValue.Index(i)); !isZero {
            if crop, ok := fieldValue.(CropInterface); ok {
              crop.Crop()
            }
          }
        }
      case reflect.Struct:
        // Get value from field
        if fieldValue, isZero := field.ValueOf(db.Statement.ReflectValue); !isZero {
          if crop, ok := fieldValue.(CropInterface); ok {
            crop.Crop()
          }
        }

        // Set value to field
        err := field.Set(db.Statement.ReflectValue, "newValue")
      }
    }

    // All fields for current model
    db.Statement.Schema.Fields

    // All primary key fields for current model
    db.Statement.Schema.PrimaryFields

    // Prioritized primary key field: field with DB name `id` or the first defined primary key
    db.Statement.Schema.PrioritizedPrimaryField

    // All relationships for current model
    db.Statement.Schema.Relationships

    // Find field with field name or db name
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
db.Callback().Create().Remove("gorm:create")
// delete callback `gorm:create` from Create callbacks
```

### Replace Callback

Replace a callback having the same name with the new one

```go
db.Callback().Create().Replace("gorm:create", newCreateFunction)
// replace callback `gorm:create` with new function `newCreateFunction` for Create process
```

### Register Callback with orders

Register callbacks with orders

```go
// before gorm:create
db.Callback().Create().Before("gorm:create").Register("update_created_at", updateCreated)

// after gorm:create
db.Callback().Create().After("gorm:create").Register("update_created_at", updateCreated)

// after gorm:query
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

### Defined Callbacks

GORM has defined [some callbacks](https://github.com/go-gorm/gorm/blob/master/callbacks/callbacks.go) to power current GORM features, check them out before starting your plugins

## Plugin

GORM provides a `Use` method to register plugins, the plugin needs to implement the `Plugin` interface

```go
type Plugin interface {
  Name() string
  Initialize(*gorm.DB) error
}
```

The `Initialize` method will be invoked when registering the plugin into GORM first time, and GORM will save the registered plugins, access them like:

```go
db.Config.Plugins[pluginName]
```

Checkout [Prometheus](prometheus.html) as example
