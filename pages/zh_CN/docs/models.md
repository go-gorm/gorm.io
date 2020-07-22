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

```go
type User struct {
  gorm.Model
  Name string
}
// 等效于
type User struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
  Name string
}
```

## 高级选项

### 字段级权限控制

可导出的字段在使用 GORM 进行 CRUD 时拥有全部的权限，此外，GORM 允许您用标签控制字段级别的权限。这样您就可以让一个字段的权限是只读、只写、只创建、只更新或者被忽略

```go
type User struct {
  Name string `gorm:"<-:create"` // 允许读和创建
  Name string `gorm:"<-:update"` // 允许读和更新
  Name string `gorm:"<-"`        // 允许读和写（创建和更新）
  Name string `gorm:"<-:false"`  // 允许读，禁止写
  Name string `gorm:"->"`        // 只读（除非有自定义配置，否则禁止写）
  Name string `gorm:"->;<-:create"` // 允许读和写
  Name string `gorm:"->:false;<-:create"` // 仅创建（禁止从 db 读）
  Name string `gorm:"-"`  // 读写操作均会忽略该字段
}
```

### <name id="time_tracking">自动的创建、更新时间</span>

GORM 约定使用 `CreatedAt`、`UpdatedAt` 追踪创建/更新时间。如果您定义了他们，GORM 在创建/更新时会自动填充 [当前时间](gorm_config.html#current_time) 至这些字段，支持 time.Time，(纳) 秒级 UNIX 时间戳等形式。

要使用不同名称的字段，您可以配置 `autoCreateTim`、`autoUpdateTim` 标签

如果您想要保存（纳）秒级 UNIX 时间戳，而不是时间，您只需简单地将 `time.Time` 修改为 `int` 即可

```go
type User struct {
  CreatedAt time.Time // 在创建时，如果该字段为零值，则将其置为当前时间
  UpdatedAt int       // 在创建时为零值，或更新时，将其 置为当前的 UNIX 秒数
  Updated   int64 `gorm:"autoUpdateTime:nano"` // 使用 UNIX 纳秒数作为更新时间
  Created   int64 `gorm:"autoCreateTime"`      // 使用 UNIX 秒数作为创建时间
}
```

### <span id="embedded_struct">嵌入结构体</span>

对于匿名字段，GORM 会将其字段包含在父结构体中，例如：

```go
type User struct {
  gorm.Model
  Name string
}
// 等效于
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
// 等效于
type Blog struct {
  ID    int64
    Name  string
    Email string
  Upvotes  int32
}
```

并且，您可以使用标签 `embeddrefix` 来为 db 中的字段名添加前缀，例如：

```go
type Blog struct {
  ID      int
  Author  Author `gorm:"embedded;embeddedPrefix:author_"`
  Upvotes int32
}
// 等效于
type Blog struct {
  ID          int64
    AuthorName  string
    AuthorEmail string
  Upvotes     int32
}
```


### 字段标签

在声明模型时，标签是可选的，GORM 支持以下标签：

标签名对大小写不敏感，但建议使用 `小驼峰（camelCase）` 的命名方式。

| 标签名            | 说明                                                                                                                                                                                                                                                                                                                                                                                                |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| column         | column db name                                                                                                                                                                                                                                                                                                                                                                                    |
| type           | column data type, prefer to use compatible general type, e.g: bool, int, uint, float, string, time, bytes, which works with other tags, like `not null`, `size`, `autoIncrement`... specified database data type like `varbinary(8)` also supported, when using specified database data type, it needs to be a full database data type, for example: `MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT` |
| size           | specifies column data size/length, e.g: `size:256`                                                                                                                                                                                                                                                                                                                                                |
| primaryKey     | specifies column as primary key                                                                                                                                                                                                                                                                                                                                                                   |
| unique         | specifies column as unique                                                                                                                                                                                                                                                                                                                                                                        |
| default        | specifies column default value                                                                                                                                                                                                                                                                                                                                                                    |
| precision      | specifies column precision                                                                                                                                                                                                                                                                                                                                                                        |
| not null       | specifies column as NOT NULL                                                                                                                                                                                                                                                                                                                                                                      |
| autoIncrement  | specifies column auto incrementable                                                                                                                                                                                                                                                                                                                                                               |
| embedded       | embed a field                                                                                                                                                                                                                                                                                                                                                                                     |
| embeddedPrefix | prefix for embedded field                                                                                                                                                                                                                                                                                                                                                                         |
| autoCreateTime | track creating time when creating, `autoCreateTime:nano` track unix nano time for `int` fields                                                                                                                                                                                                                                                                                                    |
| autoUpdateTime | track updating time when creating/updating, `autoUpdateTime:nano` track unix nano time for `int` fields                                                                                                                                                                                                                                                                                           |
| index          | create index with options, same name for multiple fields creates composite indexes, refer [Indexes](indexes.html) for details                                                                                                                                                                                                                                                                     |
| uniqueIndex    | same as `index`, but create uniqued index                                                                                                                                                                                                                                                                                                                                                         |
| check          | creates check constraint, eg: `check:(age > 13)`, refer [Constraints](constraints.html)                                                                                                                                                                                                                                                                                                        |
| <-             | set field's write permission, `<-:create` create-only field, `<-:update` update-only field, `<-:false` no permission                                                                                                                                                                                                                                                                     |
| ->             | set field's read permission                                                                                                                                                                                                                                                                                                                                                                       |
| -              | ignore this fields (disable read/write permission)                                                                                                                                                                                                                                                                                                                                                |

### 关联标签

GORM 允许通过标签为关联配置外键、约束、many2many 表，详情请参考 [关联部分](associations.html#tags)
