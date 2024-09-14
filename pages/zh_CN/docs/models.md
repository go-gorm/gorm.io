---
title: 模型定义
layout: page
---

GORM 通过将 Go 结构体（Go structs） 映射到数据库表来简化数据库交互。 了解如何在GORM中定义模型，是充分利用GORM全部功能的基础。

## 模型定义

模型是使用普通结构体定义的。 这些结构体可以包含具有基本Go类型、指针或这些类型的别名，甚至是自定义类型（只需要实现 `database/sql` 包中的[Scanner](https://pkg.go.dev/database/sql/?tab=doc#Scanner)和[Valuer](https://pkg.go.dev/database/sql/driver#Valuer)接口）。

考虑以下 `user` 模型的示例：

```go
type User struct {
  ID           uint           // Standard field for the primary key
  Name         string         // 一个常规字符串字段
  Email        *string        // 一个指向字符串的指针, allowing for null values
  Age          uint8          // 一个未签名的8位整数
  Birthday     *time.Time     // A pointer to time.Time, can be null
  MemberNumber sql.NullString // Uses sql.NullString to handle nullable strings
  ActivatedAt  sql.NullTime   // Uses sql.NullTime for nullable time fields
  CreatedAt    time.Time      // 创建时间（由GORM自动管理）
  UpdatedAt    time.Time      // 最后一次更新时间（由GORM自动管理）
}
```

在此模型中：

- 具体数字类型如 `uint`、`string`和 `uint8` 直接使用。
- 指向 `*string` 和 `*time.Time` 类型的指针表示可空字段。
- 来自 `database/sql` 包的 `sql.NullString` 和 `sql.NullTime` 用于具有更多控制的可空字段。
- `CreatedAt` 和 `UpdatedAt` 是特殊字段，当记录被创建或更新时，GORM 会自动向内填充当前时间。

除了 GORM 中模型声明的基本特性外，强调下通过 serializer 标签支持序列化也很重要。 此功能增强了数据存储和检索的灵活性，特别是对于需要自定义序列化逻辑的字段。详细说明请参见 [Serializer](serializer.html)。

### 约定

1. **主键**：GORM 使用一个名为`ID` 的字段作为每个模型的默认主键。

2. **表名**：默认情况下，GORM 将结构体名称转换为 `snake_case` 并为表名加上复数形式。 例如，一个 `User` 结构体在数据库中的表名变为 `users` 。

3. **列名**：GORM 自动将结构体字段名称转换为 `snake_case` 作为数据库中的列名。

4. **时间戳字段**：GORM使用字段 `CreatedAt` 和 `UpdatedAt` 来自动跟踪记录的创建和更新时间。

遵循这些约定可以大大减少您需要编写的配置或代码量。 但是，GORM也具有灵活性，允许您根据自己的需求自定义这些设置。 您可以在GORM的[约定](conventions.html)文档中了解更多关于自定义这些约定的信息。

### `gorm.Model`

GORM提供了一个预定义的结构体，名为`gorm.Model`，其中包含常用字段：

```go
// gorm.Model 的定义
type Model struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
}
```

- **将其嵌入在您的结构体中**: 您可以直接在您的结构体中嵌入 `gorm.Model` ，以便自动包含这些字段。 这对于在不同模型之间保持一致性并利用GORM内置的约定非常有用，请参考[嵌入结构](#embedded_struct)。

- **包含的字段**：
  - `ID` ：每个记录的唯一标识符（主键）。
  - `CreatedAt` ：在创建记录时自动设置为当前时间。
  - `UpdatedAt`：每当记录更新时，自动更新为当前时间。
  - `DeletedAt`：用于软删除（将记录标记为已删除，而实际上并未从数据库中删除）。

## 高级选项

### <span id="field_permission">字段级权限控制</span>

可导出的字段在使用 GORM 进行 CRUD 时拥有全部的权限，此外，GORM 允许您用标签控制字段级别的权限。这样您就可以让一个字段的权限是只读、只写、只创建、只更新或者被忽略

{% note warn %}
**注意：** 使用 GORM Migrator 创建表时，不会创建被忽略的字段
{% endnote %}

```go
type User struct {
  Name string `gorm:"<-:create"` // 允许读和创建
  Name string `gorm:"<-:update"` // 允许读和更新
  Name string `gorm:"<-"`        // 允许读和写（创建和更新）
  Name string `gorm:"<-:false"`  // 允许读，禁止写
  Name string `gorm:"->"`        // 只读（除非有自定义配置，否则禁止写）
  Name string `gorm:"->;<-:create"` // 允许读和写
  Name string `gorm:"->:false;<-:create"` // 仅创建（禁止从 db 读）
  Name string `gorm:"-"`  // 通过 struct 读写会忽略该字段
  Name string `gorm:"-:all"`        // 通过 struct 读写、迁移会忽略该字段
  Name string `gorm:"-:migration"`  // 通过 struct 迁移会忽略该字段
}
```

### <name id="time_tracking">创建/更新时间追踪（纳秒、毫秒、秒、Time）</span>

GORM 约定使用 `CreatedAt`、`UpdatedAt` 追踪创建/更新时间。如果您定义了这种字段，GORM 在创建、更新时会自动填充 [当前时间](gorm_config.html#now_func)

要使用不同名称的字段，您可以配置 `autoCreateTime`、`autoUpdateTime` 标签。

如果您想要保存 UNIX（毫/纳）秒时间戳，而不是 time，您只需简单地将 `time.Time` 修改为 `int` 即可

```go
type User struct {
  CreatedAt time.Time // 在创建时，如果该字段值为零值，则使用当前时间填充
  UpdatedAt int       // 在创建时该字段值为零值或者在更新时，使用当前时间戳秒数填充
  Updated   int64 `gorm:"autoUpdateTime:nano"` // 使用时间戳纳秒数填充更新时间
  Updated   int64 `gorm:"autoUpdateTime:milli"` // 使用时间戳毫秒数填充更新时间
  Created   int64 `gorm:"autoCreateTime"`      // 使用时间戳秒数填充创建时间
}
```

### <span id="embedded_struct">嵌入结构体</span>

对于匿名字段，GORM 会将其字段包含在父结构体中，例如：

```go
type Author struct {
  Name  string
  Email string
}

type Blog struct {
  Author
  ID      int
  Upvotes int32
}
// equals
type Blog struct {
  ID      int64
  Name    string
  Email   string
  Upvotes int32
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

并且，您可以使用标签 `embeddedPrefix` 来为 db 中的字段名添加前缀，例如：

```go
type Blog struct {
  ID      int
  Author  Author `gorm:"embedded;embeddedPrefix:author_"`
  Upvotes int32
}
// 等效于
type Blog struct {
  ID          int64
  AuthorName string
  AuthorEmail string
  Upvotes     int32
}
```


### <span id="tags">字段标签</span>

Tags are optional to use when declaring models, GORM supports the following tags: Tags are case insensitive, however `camelCase` is preferred. If multiple tags are used they should be separated by a semicolon (`;`). Characters that have special meaning to the parser can be escaped with a backslash (`\`) allowing them to be used as parameter values.

| 标签名                    | 说明                                                                                                                                                                                                                                         |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| column                 | 指定 db 列名                                                                                                                                                                                                                                   |
| type                   | 列数据类型，推荐使用兼容性好的通用类型，例如：所有数据库都支持 bool、int、uint、float、string、time、bytes 并且可以和其他标签一起使用，例如：`not null`、`size`, `autoIncrement`... 像 `varbinary(8)` 这样指定数据库数据类型也是支持的。在使用指定数据库数据类型时，它需要是完整的数据库数据类型，如：`MEDIUMINT UNSIGNED not NULL AUTO_INCREMENT` |
| serializer             | 指定将数据序列化或反序列化到数据库中的序列化器, 例如: `serializer:json/gob/unixtime`                                                                                                                                                                                |
| size                   | 定义列数据类型的大小或长度，例如 `size: 256`                                                                                                                                                                                                               |
| primaryKey             | 将列定义为主键                                                                                                                                                                                                                                    |
| unique                 | 将列定义为唯一键                                                                                                                                                                                                                                   |
| default                | 定义列的默认值                                                                                                                                                                                                                                    |
| precision              | 指定列的精度                                                                                                                                                                                                                                     |
| scale                  | 指定列大小                                                                                                                                                                                                                                      |
| not null               | 指定列为 NOT NULL                                                                                                                                                                                                                              |
| autoIncrement          | 指定列为自动增长                                                                                                                                                                                                                                   |
| autoIncrementIncrement | 自动步长，控制连续记录之间的间隔                                                                                                                                                                                                                           |
| embedded               | 嵌套字段                                                                                                                                                                                                                                       |
| embeddedPrefix         | 嵌入字段的列名前缀                                                                                                                                                                                                                                  |
| autoCreateTime         | 创建时追踪当前时间，对于 `int` 字段，它会追踪时间戳秒数，您可以使用 `nano`/`milli` 来追踪纳秒、毫秒时间戳，例如：`autoCreateTime:nano`                                                                                                                                                  |
| autoUpdateTime         | 创建/更新时追踪当前时间，对于 `int` 字段，它会追踪时间戳秒数，您可以使用 `nano`/`milli` 来追踪纳秒、毫秒时间戳，例如：`autoUpdateTime:milli`                                                                                                                                              |
| index                  | 根据参数创建索引，多个字段使用相同的名称则创建复合索引，查看 [索引](indexes.html) 获取详情                                                                                                                                                                                     |
| uniqueIndex            | 与 `index` 相同，但创建的是唯一索引                                                                                                                                                                                                                     |
| check                  | 创建检查约束，例如 `check:age > 13`，查看 [约束](constraints.html) 获取详情                                                                                                                                                                               |
| <-                     | 设置字段写入的权限， `<-:create` 只创建、`<-:update` 只更新、`<-:false` 无写入权限、`<-` 创建和更新权限                                                                                                                                                       |
| ->                     | 设置字段读的权限，`->:false` 无读权限                                                                                                                                                                                                                |
| -                      | 忽略该字段，`-` 表示无读写，`-:migration` 表示无迁移权限，`-:all` 表示无读写迁移权限                                                                                                                                                                                    |
| comment                | 迁移时为字段添加注释                                                                                                                                                                                                                                 |

### 关联标签

GORM 允许通过标签为关联配置外键、约束、many2many 表，详情请参考 [关联部分](associations.html#tags)
