---
title: Declaring Models
layout: page
---

GORM simplifies database interactions by mapping Go structs to database tables. Understanding how to declare models in GORM is fundamental for leveraging its full capabilities.

## Deklarasi Model

Models are defined using normal structs. These structs can contain fields with basic Go types, pointers or aliases of these types, or even custom types, as long as they implement the [Scanner](https://pkg.go.dev/database/sql/?tab=doc#Scanner) and [Valuer](https://pkg.go.dev/database/sql/driver#Valuer) interfaces from the `database/sql` package

Consider the following example of a `User` model:

```go
type User struct {
  ID           uint           // Standard field for the primary key
  Name         string         // A regular string field
  Email        *string        // A pointer to a string, allowing for null values
  Age          uint8          // An unsigned 8-bit integer
  Birthday     *time.Time     // A pointer to time.Time, can be null
  MemberNumber sql.NullString // Uses sql.NullString to handle nullable strings
  ActivatedAt  sql.NullTime   // Uses sql.NullTime for nullable time fields
  CreatedAt    time.Time      // Automatically managed by GORM for creation time
  UpdatedAt    time.Time      // Automatically managed by GORM for update time
}
```

In this model:

- Basic data types like `uint`, `string`, and `uint8` are used directly.
- Pointers to types like `*string` and `*time.Time` indicate nullable fields.
- `sql.NullString` and `sql.NullTime` from the `database/sql` package are used for nullable fields with more control.
- `CreatedAt` and `UpdatedAt` are special fields that GORM automatically populates with the current time when a record is created or updated.

In addition to the fundamental features of model declaration in GORM, it's important to highlight the support for serialization through the serializer tag. This feature enhances the flexibility of how data is stored and retrieved from the database, especially for fields that require custom serialization logic, See [Serializer](serializer.html) for a detailed explanation

### Konvensi

1. **Primary Key**: GORM uses a field named `ID` as the default primary key for each model.

2. **Table Names**: By default, GORM converts struct names to `snake_case` and pluralizes them for table names. For instance, a `User` struct becomes `users` in the database.

3. **Column Names**: GORM automatically converts struct field names to `snake_case` for column names in the database.

4. **Timestamp Fields**: GORM uses fields named `CreatedAt` and `UpdatedAt` to automatically track the creation and update times of records.

Following these conventions can greatly reduce the amount of configuration or code you need to write. However, GORM is also flexible, allowing you to customize these settings if the default conventions don't fit your requirements. You can learn more about customizing these conventions in GORM's documentation on [conventions](conventions.html).

### `gorm.Model`

GORM provides a predefined struct named `gorm.Model`, which includes commonly used fields:

```go
// definisi gorm.Model
type Model struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
}
```

- **Embedding in Your Struct**: You can embed `gorm.Model` directly in your structs to include these fields automatically. This is useful for maintaining consistency across different models and leveraging GORM's built-in conventions, refer [Embedded Struct](#embedded_struct)

- **Fields Included**:
  - `ID`: A unique identifier for each record (primary key).
  - `CreatedAt`: Automatically set to the current time when a record is created.
  - `UpdatedAt`: Automatically updated to the current time whenever a record is updated.
  - `DeletedAt`: Used for soft deletes (marking records as deleted without actually removing them from the database).

## Advanced

### <span id="field_permission">Field-Level Permission</span>

Exported fields have all permissions when doing CRUD with GORM, and GORM allows you to change the field-level permission with tag, so you can make a field to be read-only, write-only, create-only, update-only or ignored

{% note warn %}
**CATATAN** *field* yang diabaikan tidak akan dibuat saat menggunakan GORM Migrator untuk membuat tabel
{% endnote %}

```go
type User struct {
  Name string `gorm:"<-:create"` // allow read and create
  Name string `gorm:"<-:update"` // allow read and update
  Name string `gorm:"<-"`        // allow read and write (create and update)
  Name string `gorm:"<-:false"`  // allow read, disable write permission
  Name string `gorm:"->"`        // readonly (disable write permission unless it configured)
  Name string `gorm:"->;<-:create"` // allow read and create
  Name string `gorm:"->:false;<-:create"` // createonly (disabled read from db)
  Name string `gorm:"-"`            // ignore this field when write and read with struct
  Name string `gorm:"-:all"`        // ignore this field when write, read and migrate with struct
  Name string `gorm:"-:migration"`  // ignore this field when migrate with struct
}
```

### <name id="time_tracking">Creating/Updating Time/Unix (Milli/Nano) Seconds Tracking</span>

GORM menggunakan `CreatedAt`, `UpdatedAt` untuk melacak waktu pembuatan/pembaruan berdasarkan konvensi, dan GORM akan menyetel [waktu saat ini](gorm_config.html#now_func) saat membuat/memperbarui jika *field*-nya ditentukan

Untuk menggunakan *field* dengan nama yang berbeda, Anda dapat mengonfigurasi *field* tersebut dengan tag `autoCreateTime`, `autoUpdateTime`

Jika Anda lebih suka menyimpan UNIX (mili/nano) detik daripada waktu, Anda cukup mengubah tipe data *field* dari `time.Time` menjadi `int`

```go
type User struct {
  CreatedAt time.Time // Set to current time if it is zero on creating
  UpdatedAt int       // Set to current unix seconds on updating or if it is zero on creating
  Updated   int64 `gorm:"autoUpdateTime:nano"` // Use unix nano seconds as updating time
  Updated   int64 `gorm:"autoUpdateTime:milli"`// Use unix milli seconds as updating time
  Created   int64 `gorm:"autoCreateTime"`      // Use unix seconds as creating time
}
```

### <span id="embedded_struct">Embedded Struct</span>

Untuk *field* anonim, GORM akan memasukkan *field*-nya ke dalam struct induknya, misalnya:

```go
type User struct {
  gorm.Model
  Name string
}
// equals
type User struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
  Name string
}
```

For a normal struct field, you can embed it with the tag `embedded`, for example:

```go
type Author struct {
    Name  string
    Email string
}

type Blog struct {
  ID      int
  Author  Author `gorm:"embedded"`
  Upvotes int32
}
// equals
type Blog struct {
  ID    int64
    Name  string
    Email string
  Upvotes  int32
}
```

And you can use tag `embeddedPrefix` to add prefix to embedded fields' db name, for example:

```go
type Blog struct {
  ID      int
  Author  Author `gorm:"embedded;embeddedPrefix:author_"`
  Upvotes int32
}
// equals
type Blog struct {
  ID          int64
    AuthorName  string
    AuthorEmail string
  Upvotes     int32
}
```


### <span id="tags">Fields Tags</span>

Tag bersifat opsional untuk digunakan saat mendeklarasikan model, GORM mendukung tag berikut: Tag bersifat *case insensitive*, namun `camelCase` lebih disukai.

| Nama Tag               | Deskripsi                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| column                 | column db name                                                                                                                                                                                                                                                                                                                                                                                                                                |
| type                   | column data type, prefer to use compatible general type, e.g: bool, int, uint, float, string, time, bytes, which works for all databases, and can be used with other tags together, like `not null`, `size`, `autoIncrement`... specified database data type like `varbinary(8)` also supported, when using specified database data type, it needs to be a full database data type, for example: `MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT` |
| serializer             | specifies serializer for how to serialize and deserialize data into db, e.g: `serializer:json/gob/unixtime`                                                                                                                                                                                                                                                                                                                                   |
| size                   | specifies column data size/length, e.g: `size:256`                                                                                                                                                                                                                                                                                                                                                                                            |
| primaryKey             | specifies column as primary key                                                                                                                                                                                                                                                                                                                                                                                                               |
| unique                 | specifies column as unique                                                                                                                                                                                                                                                                                                                                                                                                                    |
| default                | specifies column default value                                                                                                                                                                                                                                                                                                                                                                                                                |
| precision              | specifies column precision                                                                                                                                                                                                                                                                                                                                                                                                                    |
| scale                  | specifies column scale                                                                                                                                                                                                                                                                                                                                                                                                                        |
| not null               | specifies column as NOT NULL                                                                                                                                                                                                                                                                                                                                                                                                                  |
| autoIncrement          | specifies column auto incrementable                                                                                                                                                                                                                                                                                                                                                                                                           |
| autoIncrementIncrement | auto increment step, controls the interval between successive column values                                                                                                                                                                                                                                                                                                                                                                   |
| embedded               | embed the field                                                                                                                                                                                                                                                                                                                                                                                                                               |
| embeddedPrefix         | column name prefix for embedded fields                                                                                                                                                                                                                                                                                                                                                                                                        |
| autoCreateTime         | track current time when creating, for `int` fields, it will track unix seconds, use value `nano`/`milli` to track unix nano/milli seconds, e.g: `autoCreateTime:nano`                                                                                                                                                                                                                                                                         |
| autoUpdateTime         | track current time when creating/updating, for `int` fields, it will track unix seconds, use value `nano`/`milli` to track unix nano/milli seconds, e.g: `autoUpdateTime:milli`                                                                                                                                                                                                                                                               |
| index                  | create index with options, use same name for multiple fields creates composite indexes, refer [Indexes](indexes.html) for details                                                                                                                                                                                                                                                                                                             |
| uniqueIndex            | same as `index`, but create uniqued index                                                                                                                                                                                                                                                                                                                                                                                                     |
| check                  | creates check constraint, eg: `check:age > 13`, refer [Constraints](constraints.html)                                                                                                                                                                                                                                                                                                                                                      |
| <-                     | set field's write permission, `<-:create` create-only field, `<-:update` update-only field, `<-:false` no write permission, `<-` create and update permission                                                                                                                                                                                                                                                                     |
| ->                     | set field's read permission, `->:false` no read permission                                                                                                                                                                                                                                                                                                                                                                                 |
| -                      | ignore this field, `-` no read/write permission, `-:migration` no migrate permission, `-:all` no read/write/migrate permission                                                                                                                                                                                                                                                                                                                |
| comment                | add comment for field when migration                                                                                                                                                                                                                                                                                                                                                                                                          |

### Associations Tags

GORM allows configure foreign keys, constraints, many2many table through tags for Associations, check out the [Associations section](associations.html#tags) for details
