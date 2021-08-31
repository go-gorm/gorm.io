---
title: Declaring Models
layout: page
---

## Deklarasi Model

Model adalah struct biasa dengan type basic Go, pointer/aliasnya type custom yang mengimplementasikan interface [Scanner](https://pkg.go.dev/database/sql/?tab=doc#Scanner) dan [Valuer](https://pkg.go.dev/database/sql/driver#Valuer)

Contoh:

```go
type User struct {
  ID           uint
  Name         string
  Email        *string
  Age          uint8
  Birthday     *time.Time
  MemberNumber sql.NullString
  ActivatedAt  sql.NullTime
  CreatedAt    time.Time
  UpdatedAt    time.Time
}
```

## Konvensi

GORM lebih memilih konvensi daripada konfigurasi, secara default, GORM menggunakan `ID` sebagai *primary key*, menjamak nama struct menjadi `snake_cases` sebagai nama tabel, `snake_case` sebagai nama kolom, dan menggunakan `CreatedAt`, `UpdatedAt` untuk melacak waktu pembuatan/pembaruan

Jika Anda mengikuti konvensi yang diadopsi oleh GORM, Anda hanya perlu menulis sedikit konfigurasi/kode, Jika konvensi tidak sesuai dengan kebutuhan Anda, [GORM memungkinkan Anda untuk mengonfigurasinya](conventions.html)

## gorm.Model

GORM mendefinisikan struct `gorm.Model`, yang mencakup *field* `ID`, `CreatedAt`, `UpdatedAt`, ``DeletedAt< /kode></p>

<pre><code class="go">// definisi gorm.Model
type Model struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
}
``</pre>

Anda dapat menyematkannya ke dalam struct Anda untuk menyertakan *field* tersebut, lihat [Embedded Struct](#embedded_struct)

## Advanced

### <span id="field_permission">Field-Level Permission</span>

Exported fields have all permission when doing CRUD with GORM, and GORM allows you to change the field-level permission with tag, so you can make a field to be read-only, write-only, create-only, update-only or ignored

{% note warn %}
**NOTE** ignored fields won't be created when using GORM Migrator to create table
{% endnote %}

```go
type User struct {
  Name string `gorm:"<-:create"` // allow read and create
  Name string `gorm:"<-:update"` // allow read and update
  Name string `gorm:"<-"`        // allow read and write (create and update)
  Name string `gorm:"<-:false"`  // allow read, disable write permission
  Name string `gorm:"->"`        // readonly (disable write permission unless it configured )
  Name string `gorm:"->;<-:create"` // allow read and create
  Name string `gorm:"->:false;<-:create"` // createonly (disabled read from db)
  Name string `gorm:"-"`  // ignore this field when write and read with struct
}
```

### <name id="time_tracking">Creating/Updating Time/Unix (Milli/Nano) Seconds Tracking</span>

GORM use `CreatedAt`, `UpdatedAt` to track creating/updating time by convention, and GORM will set the  [current time](gorm_config.html#now_func) when creating/updating if the fields are defined

To use fields with a different name, you can configure those fields with tag `autoCreateTime`, `autoUpdateTime`

If you prefer to save UNIX (milli/nano) seconds instead of time, you can simply change the field's data type from `time.Time` to `int`

```go
type User struct {
  CreatedAt time.Time // Set to current time if it is zero on creating
  UpdatedAt int       // Set to current unix seconds on updaing or if it is zero on creating
  Updated   int64 `gorm:"autoUpdateTime:nano"` // Use unix nano seconds as updating time
  Updated   int64 `gorm:"autoUpdateTime:milli"`// Use unix milli seconds as updating time
  Created   int64 `gorm:"autoCreateTime"`      // Use unix seconds as creating time
}
```

### <span id="embedded_struct">Embedded Struct</span>

For anonymous fields, GORM will include its fields into its parent struct, for example:

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

| Tag Name               | Description                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| column                 | column db name                                                                                                                                                                                                                                                                                                                                                                                                                                |
| type                   | column data type, prefer to use compatible general type, e.g: bool, int, uint, float, string, time, bytes, which works for all databases, and can be used with other tags together, like `not null`, `size`, `autoIncrement`... specified database data type like `varbinary(8)` also supported, when using specified database data type, it needs to be a full database data type, for example: `MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT` |
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
| -                      | ignore this field, `-` no read/write permission                                                                                                                                                                                                                                                                                                                                                                                               |
| comment                | add comment for field when migration                                                                                                                                                                                                                                                                                                                                                                                                          |

### Associations Tags

GORM allows configure foreign keys, constraints, many2many table through tags for Associations, check out the [Associations section](associations.html#tags) for details
