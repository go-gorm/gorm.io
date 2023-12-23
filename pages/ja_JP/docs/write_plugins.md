---
title: プラグインの作成
layout: page
---

## Callbacks

GORM leverages `Callbacks` to power its core functionalities. These callbacks provide hooks for various database operations like `Create`, `Query`, `Update`, `Delete`, `Row`, and `Raw`, allowing for extensive customization of GORM's behavior.

Callbacks are registered at the global `*gorm.DB` level, not on a session basis. This means if you need different callback behaviors, you should initialize a separate `*gorm.DB` instance.

### Registering a Callback

You can register a callback for specific operations. For example, to add a custom image cropping functionality:

```go
func cropImage(db *gorm.DB) {
  if db.Statement.Schema != nil {
    // crop image fields and upload them to CDN, dummy code
    for _, field := range db.Statement.Schema.Fields {
      switch db.Statement.ReflectValue.Kind() {
      case reflect.Slice, reflect.Array:
        for i := 0; i < db.Statement.ReflectValue.Len(); i++ {
          // Get value from field
          if fieldValue, isZero := field.ValueOf(db.Statement.Context, db.Statement.ReflectValue.Index(i)); !isZero {
            if crop, ok := fieldValue.(CropInterface); ok {
              crop.Crop()
            }
          }
        }
      case reflect.Struct:
        // Get value from field
        if fieldValue, isZero := field.ValueOf(db.Statement.Context, db.Statement.ReflectValue); !isZero {
          if crop, ok := fieldValue.(CropInterface); ok {
            crop.Crop()
          }
        }

        // Set value to field
        err := field.Set(db.Statement.Context, db.Statement.ReflectValue, "newValue")
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

// Register the callback for the Create operation
db.Callback().Create().Register("crop_image", cropImage)
```

### Deleting a Callback

If a callback is no longer needed, it can be removed:

```go
// Remove the 'gorm:create' callback from Create operations
db.Callback().Create().Remove("gorm:create")
```

### Replacing a Callback

Callbacks with the same name can be replaced with a new function:

```go
// Replace the 'gorm:create' callback with a new function
db.Callback().Create().Replace("gorm:create", newCreateFunction)
```

### Ordering Callbacks

Callbacks can be registered with specific orders to ensure they execute at the right time in the operation lifecycle.

```go
// Register to execute before the 'gorm:create' callback
db.Callback().Create().Before("gorm:create").Register("update_created_at", updateCreated)

// Register to execute after the 'gorm:create' callback
db.Callback().Create().After("gorm:create").Register("update_created_at", updateCreated)

// Register to execute after the 'gorm:query' callback
db.Callback().Query().After("gorm:query").Register("my_plugin:after_query", afterQuery)

// Register to execute after the 'gorm:delete' callback
db.Callback().Delete().After("gorm:delete").Register("my_plugin:after_delete", afterDelete)

// Register to execute before the 'gorm:update' callback
db.Callback().Update().Before("gorm:update").Register("my_plugin:before_update", beforeUpdate)

// Register to execute before 'gorm:create' and after 'gorm:before_create'
db.Callback().Create().Before("gorm:create").After("gorm:before_create").Register("my_plugin:before_create", beforeCreate)

// Register to execute before any other callbacks
db.Callback().Create().Before("*").Register("update_created_at", updateCreated)

// Register to execute after any other callbacks
db.Callback().Create().After("*").Register("update_created_at", updateCreated)
```

### Predefined Callbacks

GORM comes with a set of predefined callbacks that drive its standard features. It's recommended to review these [defined callbacks](https://github.com/go-gorm/gorm/blob/master/callbacks/callbacks.go) before creating custom plugins or additional callback functions.

## Plugins

GORM's plugin system allows for the extension and customization of its core functionalities. Plugins in GORM are integrated using the `Use` method and must conform to the `Plugin` interface.

### The `Plugin` Interface

To create a plugin for GORM, you need to define a struct that implements the `Plugin` interface:

```go
type Plugin interface {
  Name() string
  Initialize(*gorm.DB) error
}
```

- **`Name` Method**: Returns a unique string identifier for the plugin.
- **`Initialize` Method**: Contains the logic to set up the plugin. This method is called when the plugin is registered with GORM for the first time.

### Registering a Plugin

Once your plugin conforms to the `Plugin` interface, you can register it with a GORM instance:

```go
// Example of registering a plugin
db.Use(MyCustomPlugin{})
```

### Accessing Registered Plugins

After a plugin is registered, it is stored in GORM's configuration. You can access registered plugins via the `Plugins` map:

```go
// Access a registered plugin by its name
plugin := db.Config.Plugins[pluginName]
```

### Practical Example: Prometheus Plugin

An example of a GORM plugin is the Prometheus plugin, which integrates Prometheus monitoring with GORM:

```go
// Registering the Prometheus plugin
db.Use(prometheus.New(prometheus.Config{
  // Configuration options here
}))
```

[Prometheus plugin documentation](prometheus.html) provides detailed information on its implementation and usage.

### Benefits of Using Plugins

- **Extensibility**: Plugins offer a way to enhance GORM's capabilities without modifying its core code.
- **Customization**: They enable customization of GORM's behavior to fit specific application requirements.
- **Modularity**: Plugins promote a modular architecture, making it easier to maintain and update different aspects of the application.
