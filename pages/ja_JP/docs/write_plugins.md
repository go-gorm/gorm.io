---
title: プラグインの作成
layout: page
---

## Callbacks

GORM内部では、 `Callbacks` の技術が活かされています。GORMには `Create`, `Query`, `Update`, `Delete`, `Row`, `Raw` 処理のcallbackが用意されています。これらのcallbackを使うことでGORMを自由にカスタマイズすることができます。

Callbacks はグローバルな `*gorm.DB` に登録されます（セッションレベルではありません）。そのため、別のcallbackが登録された `*gorm.DB` が必要な場合は、新規の `*gorm.DB` を用意する必要があります。

### Callbackを登録する

独自のcallbackを登録できます

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

db.Callback().Create().Register("crop_image", cropImage)
// register a callback for Create process
```

### Callbackを削除する

指定したcallbackを削除することができます

```go
db.Callback().Create().Remove("gorm:create")
// delete callback `gorm:create` from Create callbacks
```

### Callbackを置き換える

同じ名称を指定することでcallbackを置き換えることができます

```go
db.Callback().Create().Replace("gorm:create", newCreateFunction)
// replace callback `gorm:create` with new function `newCreateFunction` for Create process
```

### 実行順序を指定してCallbackを登録する

実行順序を指定してCallbackを登録することができます。

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

### 定義済みのCallbacks

GORMをより高機能にするために、 GORMにはすでに [定義されているCallbacks](https://github.com/go-gorm/gorm/blob/master/callbacks/callbacks.go) があります。プラグインを作成する前にそれらをチェックしてみるとよいでしょう。

## プラグイン

GORMにはプラグインを登録するための `Use` メソッドがあります。プラグインは `Plugin` インターフェイスを実装している必要があります。

```go
type Plugin interface {
  Name() string
  Initialize(*gorm.DB) error
}
```

GORMにプラグインを登録すると `Initialize` メソッドが実行されます。 GORMは登録されたプラグインを保存しているため、以下のようにアクセスすることができます:

```go
db.Config.Plugins[pluginName]
```

プラグインの例として [Prometheus](prometheus.html) を参照するとよいでしょう。
