---
title: Declaring Models
layout: page
---

## Declaring Models

Models are normal structs with basic Go types, pointers/alias of them or custom types implementing [Scanner](https://pkg.go.dev/database/sql/sql#Scanner) and [Valuer](https://pkg.go.dev/database/sql/driver#Valuer) interfaces

For Example:

```go
type User struct {
  ID           uint
  Name         string
  Email        *string
  Age          uint8
  Birthday     *time.Time
  MemberNumber sql.NullString
  ActivedAt    sql.NullTime
  CreatedAt    time.Time
  UpdatedAt    time.Time
}
```

## Conventions

GORM prefer convention over configuration, by default, GORM uses `ID` as primary key, pluralize struct name to `snake_cases` as table name, `snake_case` as column name, and uses `CreatedAt`, `UpdatedAt` to track creating/updating time.

If you follow the conventions adopted by GORM, you'll need to write very little configuration/code, but if it doesn't match your requirements, [GORM allows you to configure them](conventions.html).

## gorm.Model

GORM defined a `gorm.Model` struct, which includes fields `ID`, `CreatedAt`, `UpdatedAt`, `DeletedAt`

```go
// gorm.Model definition
type Model struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
}
```

You can embed it into your model to include those fields, refer [Embedded Struct](#embedded_struct)

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

## Advanced

### Field Permissions

All exported fields will be used when doing CRUD with GORM by default.

But GORM allows you set field-level permission with tags, you can make a field to read-only, write-only, create-only, update-only or ignored

```go
type User struct {
  Name string `gorm:"<-:create"` // allow read and create
  Name string `gorm:"<-:update"` // allow read and update
  Name string `gorm:"<-"`        // allow read and write (create and update)
  Name string `gorm:"->:false;<-:create"` // createonly (disabled read from db)
  Name string `gorm:"->"` // readonly
  Name string `gorm:"-"`  // ignored
}
```

### Auto Creating/Updating Time/Unix (Nano) Second

GORM use `CreatedAt`, `UpdatedAt` to track creating/updating time by convention, and GORM will fill [current time](gorm_config.html#current_time) into it when creating/updating if they are defined.

To use other fields, you can configure those fields with tags `autoCreateTime`, `autoUpdateTime`, if you prefer to save unix (nano) seconds instead of time, you can simply change field's data type from `time.Time` to `int`

```go
type User struct {
  CreatedAt time.Time // Set to current time if it is zero on creating
  UpdatedAt int       // Set to current unix seconds on updaing or if it is zero on creating
  Updated   int64 `gorm:"autoUpdateTime:nano"` // Use unix NANO seconds as updating time
  Created   int64 `gorm:"autoCreateTime"`      // Use unix seconds as creating time
}
```

### <span id="embedded_struct">Embedded Struct</span>

For any anonymous fields, GORM will includes its fields into its parent struct, for example:

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

You can also embed a normal struct field using tag `embedded`, for example:

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

With the help of tag `embeddedPrefix`, you can add prefix to embedded fields' db name, for example:

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


### Fields Tags

Tags are optional to use when declaring models, GORM supports the following tags:

Name case doesn't matter, `camelCase` is preferred to use.

| Tag            | Description                                                            |
| ---            | ---                                                                    |
| column         | column db name                                                  |
| type           | column data type, prefer to use compatible general type, e.g: bool, int, uint, float, string, time, bytes, specified database data type like varbinary(8) also supported |
| size           | specifies column data size/length, e.g: `size:256`                                                  |
| primaryKey     | specifies column as primary key                                        |
| unique         | specifies column as unique                                             |
| default        | specifies column default value                                         |
| precision      | specifies column precision                                             |
| not null       | specifies column as NOT NULL                                           |
| autoIncrement  | specifies column auto incrementable                                    |
| index          | create index with options, same name for multiple fields creates composite indexes |
| uniqueIndex    | same as `index`, but create uniqued index                              |
| embedded       | set field to embedded                                                  |
| embeddedPrefix | Set embedded field's prefix                                            |
| autoCreateTime | track creating time when creating, `autoCreateTime:nano` track unix nano time for `int` fields |
| autoUpdateTime | track updating time when creating/updating, `autoUpdateTime:nano` track unix nano time for `int` fields                                                  |
| <-             | set field's write permission, `<-:create` create-only field, `<-:update` update-only field, `<-:false` no permission |
| ->             | set field's read permission, `->:false` disable read, `->` or `->:true` readonly, disable write permission unless configured it |
| -              | ignore this fields (disable read/write permission)                                                     |
| check          | creates check constraint, eg: `check:(age > 13)`, refer [Constraints](constraints.html) |

### Associations Tags

GORM allows configure foreign keys, constraints, many2many table through tags for Associations, check out the [Associations section](associations.html#tags) for details
