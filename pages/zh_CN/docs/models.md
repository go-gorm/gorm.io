---
title: 模型定义
layout: page
---

## 模型定义

模型（Models）通常只是正常的 golang structs、基本的 go 类型或它们的指针。 同时也支持[`sql.Scanner`](https://golang.org/pkg/database/sql/#Scanner)及[`driver.Valuer`](https://golang.org/pkg/database/sql/driver/#Valuer) 接口（interfaces）。

模型（Model）示例:

```go
type User struct {
  gorm.Model
  Name         string
  Age          sql.NullInt64
  Birthday     *time.Time
  Email        string  `gorm:"type:varchar(100);unique_index"`
  Role         string  `gorm:"size:255"` // 设置字段大小为255
  MemberNumber *string `gorm:"unique;not null"` // 设置会员号（member number）唯一并且不为空
  Num          int     `gorm:"AUTO_INCREMENT"` // 设置 num 为自增类型
  Address      string  `gorm:"index:addr"` // 给address字段创建名为addr的索引
  IgnoreMe     int     `gorm:"-"` // 忽略本字段
}
```

## 结构体标记（tags）

标记（tags）在声明模型时是可选项。gorm 支持以下标记:

### 支持的结构体标记（Struct tags）

| 结构体标记（Tag）      | 描述                            |
| --------------- | ----------------------------- |
| Column          | 指定列名                          |
| Type            | 指定列数据类型                       |
| Size            | 指定列大小, 默认值255                 |
| PRIMARY_KEY     | 将列指定为主键                       |
| UNIQUE          | 将列指定为唯一                       |
| DEFAULT         | 指定列默认值                        |
| PRECISION       | 指定列精度                         |
| NOT NULL        | 将列指定为非 NULL                   |
| AUTO_INCREMENT  | 指定列是否为自增类型                    |
| INDEX           | 创建具有或不带名称的索引, 如果多个索引同名则创建复合索引 |
| UNIQUE_INDEX    | 和 `INDEX` 类似，只不过创建的是唯一索引      |
| EMBEDDED        | 将结构设置为嵌入                      |
| EMBEDDED_PREFIX | 设置嵌入结构的前缀                     |
| -               | 忽略此字段                         |

### 关联关系相关的结构体标记（tags）

Check out the Associations section for details

| 结构体标记（Tag）                         | 描述                                             |
| ---------------------------------- | ---------------------------------------------- |
| MANY2MANY                          | 设置join的表                                       |
| FOREIGNKEY                         | 设置外键                                           |
| ASSOCIATION_FOREIGNKEY             | Specifies association foreign key              |
| POLYMORPHIC                        | Specifies polymorphic type                     |
| POLYMORPHIC_VALUE                  | Specifies polymorphic value                    |
| JOINTABLE_FOREIGNKEY               | Specifies foreign key of jointable             |
| ASSOCIATION_JOINTABLE_FOREIGNKEY | Specifies association foreign key of jointable |
| SAVE_ASSOCIATIONS                  | AutoSave associations or not                   |
| ASSOCIATION_AUTOUPDATE             | AutoUpdate associations or not                 |
| ASSOCIATION_AUTOCREATE             | AutoCreate associations or not                 |
| ASSOCIATION_SAVE_REFERENCE       | AutoSave associations reference or not         |
| PRELOAD                            | Auto Preload associations or not               |
