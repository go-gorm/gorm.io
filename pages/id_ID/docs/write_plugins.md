---
title: Membuat Plugin
layout: page
---

## Panggilan Balik

GORM tersendiri mendukung `Callbacks`, memiliki panggilan balik untuk `Create`, `Query`, `Update`, `Delete`, `Row`, `Raw`, Anda dapat sepenuhnya menyesuaikan GORM dengan mereka seperti yang Anda inginkan

Callback terdaftar ke `*gorm.DB` global, bukan tingkat sesi, jika Anda memerlukan `*gorm.DB` dengan callback yang berbeda, Anda perlu menginisialisasi `*gorm.DB` lain

### Mendaftarkan Panggilan Balik

Daftarkan panggilan balik ke panggilan balik

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

### Menhapus Panggilan Balik

Hapus panggilan balik dari panggilan balik

```go
db.Callback().Create().Remove("gorm:create")
// hapus panggilan balik `gorm: create` dari Buat panggilan balik
```

### Mengganti Panggilan Balik

Ganti panggilan balik yang memiliki nama yang sama dengan yang baru

```go
db.Callback().Create().Replace("gorm:create", newCreateFunction)
// ganti callback `gorm:create` dengan fungsi baru `newCreateFunction` untuk proses Create
```

### Daftarkan Panggilan Balik dengan `Orders`

Daftarkan Panggilan Balik dengan `Orders`

```go
// sebelum gorm:create
db.Callback().Create().Before("gorm:create").Register("update_created_at", updateCreated)

// setelah gorm:create
db.Callback().Create().After("gorm:create").Register("update_created_at", updateCreated)

// setelah gorm:query
db.Callback().Query().After("gorm:query").Register("my_plugin:after_query", afterQuery)

// setelah gorm:delete
db.Callback().Delete().After("gorm:delete").Register("my_plugin:after_delete", afterDelete)

// sebelum gorm: perbarui
db.Callback().Update().Before("gorm:update").Register("my_plugin:before_update", beforeUpdate)

// sebelum gorm:buat dan setelah gorm:sebelum_buat
db.Callback().Create().Before("gorm:create").After("gorm:before_create").Register("my_plugin:before_create", beforeCreate)

// sebelum panggilan balik lainnya
db.Callback().Create().Before("*").Register("update_created_at", updateCreated)

// setelah panggilan balik lainnya
db.Callback().Create().After("*").Register("update_created_at", updateCreated)
```

### Mendefinisikan Panggilan Balik

GORM telah menetapkan [beberapa panggilan balik](https://github.com/go-gorm/gorm/blob/master/callbacks/callbacks.go) untuk mengaktifkan fitur GORM saat ini, periksa sebelum memulai plugin Anda

## Plugin

GORM menyediakan metode `Use` untuk mendaftarkan plugin, plugin perlu mengimplementasikan antarmuka `Plugin`

```go
type Plugin interface {
  Name() string
  Initialize(*gorm.DB) error
}
```

Metode `Initialize` akan dipanggil saat mendaftarkan plugin ke GORM pertama kali, dan GORM akan menyimpan plugin yang terdaftar, mengaksesnya seperti:

```go
db.Config.Plugins[pluginName]
```

Lihat [Prometheus](prometheus.html) sebagai contoh
