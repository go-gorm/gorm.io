---
title: 模型定义
layout: page
---

## 模型定义

模型一般基于 Go 的基本数据类型、实现了 [Scanner](https://pkg.go.dev/database/sql/sql#Scanner) 和 [Valuer](https://pkg.go.dev/database/sql/driver#Valuer) 接口的自定义类型以及它们的指针/别名

例如：

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

## 约定

GORM 倾向于约定，而不是配置。默认情况下，GORM 使用 `ID` 作为主键，使用结构体名的 `蛇形复数` 作为表名，字段名的 `蛇形` 作为列名，并使用 `CreatedAt`、`UpdatedAt` 字段追踪创建、更新时间

遵循 GORM 已有的约定，可以减少您的配置和代码量。如果约定不符合您的需求，[GORM 允许您自定义配置它们](conventions.html)

## gorm.Model

GORM 定义一个 `gorm.Model` 结构体，其包括字段 `ID`、`CreatedAt`、`UpdatedAt`、`DeletedAt`

```go
// gorm.Model 的定义
type Model struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
}
```

您可以将它嵌入到您的结构体中，以包含这几个字段，详情请参考 [嵌入结构体](#embedded_struct)

## 高级选项

### 字段级权限控制

Exported fields have all permission when doing CRUD with GORM, and GORM allows you to change the field-level permission with tag, so you can make a field to be read-only, write-only, create-only, update-only or ignored

**注意：** 使用 GORM Migrator 创建表时，不会创建被忽略的字段

```go
type User struct {
  Name string `gorm:"<-:create"` // allow read and create
  Name string `gorm:"<-:update"` // allow read and update
  Name string `gorm:"<-"`        // allow read and write (create and update)
  Name string `gorm:"<-:false"`  // allow read, disable write permission
  Name string `gorm:"->"`        // readonly (disable write permission unless it configured )
  Name string `gorm:"->;<-:create"` // allow read and create
  Name string `gorm:"->:false;<-:create"` // createonly (disabled read from db)
  Name string `gorm:"-"`  // ignore this field when write and read
}
```

### <name id="time_tracking">创建/更新时间追踪（纳秒、毫秒、秒、Time）</span>

GORM use `CreatedAt`, `UpdatedAt` to track creating/updating time by convention, and GORM will fill [current time](gorm_config.html#now_func) into it when creating/updating if they are defined

要使用不同名称的字段，您可以配置 `autoCreateTim`、`autoUpdateTim` 标签

如果您想要保存纳秒、毫秒、秒级 UNIX 时间戳，而不是 time，您只需简单地将 `time.Time` 修改为 `int` 即可

```go
type User struct {
  CreatedAt time.Time // Set to current time if it is zero on creating
  UpdatedAt int       // Set to current unix seconds on updaing or if it is zero on creating
  Updated   int64 `gorm:"autoUpdateTime:nano"` // Use unix nano seconds as updating time
  Updated   int64 `gorm:"autoUpdateTime:milli"`// Use unix milli seconds as updating time
  Created   int64 `gorm:"autoCreateTime"`      // Use unix seconds as creating time
}
```

### <span id="embedded_struct">嵌入结构体</span>

对于匿名字段，GORM 会将其字段包含在父结构体中，例如：

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

对于正常的结构体字段，你也可以通过标签 `embedded` 将其嵌入，例如：

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


### <span id="tags">字段标签</span>

Tags are optional to use when declaring models, GORM supports the following tags: Tag name case doesn't matter, `camelCase` is preferred to use.

| 标签名            | 说明                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| column         | 指定 db 列名                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| type           | column data type, prefer to use compatible general type, e.g: bool, int, uint, float, string, time, bytes, which works for all databases, and can be used with other tags together, like `not null`, `size`, `autoIncrement`... specified database data type like `varbinary(8)` also supported, when using specified database data type, it needs to be a full database data type, for example: `MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT` |
| size           | 指定列大小，例如：`size:256`                                                                                                                                                                                                                                                                                                                                                                                                                           |
| primaryKey     | 指定列为主键                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| unique         | 指定列为唯一                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| default        | 指定列的默认值                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| precision      | 指定列的精度                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| scale          | specifies column scale                                                                                                                                                                                                                                                                                                                                                                                                                        |
| not null       | specifies column as NOT NULL                                                                                                                                                                                                                                                                                                                                                                                                                  |
| autoIncrement  | specifies column auto incrementable                                                                                                                                                                                                                                                                                                                                                                                                           |
| embedded       | embed the field                                                                                                                                                                                                                                                                                                                                                                                                                               |
| embeddedPrefix | column name prefix for embedded fields                                                                                                                                                                                                                                                                                                                                                                                                        |
| autoCreateTime | track current time when creating, for `int` fields, it will track unix seconds, use value `nano`/`milli` to track unix nano/milli seconds, e.g: `autoCreateTime:nano`                                                                                                                                                                                                                                                                         |
| autoUpdateTime | track current time when creating/updating, for `int` fields, it will track unix seconds, use value `nano`/`milli` to track unix nano/milli seconds, e.g: `autoUpdateTime:milli`                                                                                                                                                                                                                                                               |
| index          | create index with options, use same name for multiple fields creates composite indexes, refer [Indexes](indexes.html) for details                                                                                                                                                                                                                                                                                                             |
| uniqueIndex    | same as `index`, but create uniqued index                                                                                                                                                                                                                                                                                                                                                                                                     |
| check          | creates check constraint, eg: `check:age > 13`, refer [Constraints](constraints.html)                                                                                                                                                                                                                                                                                                                                                      |
| <-             | set field's write permission, `<-:create` create-only field, `<-:update` update-only field, `<-:false` no write permission, `<-` create and update permission                                                                                                                                                                                                                                                                     |
| ->             | set field's read permission, `->:false` no read permission                                                                                                                                                                                                                                                                                                                                                                                 |
| -              | ignore this fields, `-` no read/write permission                                                                                                                                                                                                                                                                                                                                                                                              |

### 关联标签

GORM allows configure foreign keys, constraints, many2many table through tags for Associations, check out the [Associations section](associations.html#tags) for details
