---
title: 复合主键
layout: page
---

将多个字段设置为 primary key 以启用复合主键

```go
type Product struct {
   ID           string `gorm:"primary_key"`
   LanguageCode string `gorm:"primary_key"`
   Code         string
   Name         string
}
```

请注意，默认情况下，带有 `主键` 标签的整形字段的会 `自动增长`。 这可能会导致多个自动增长的整形主键，而不是单个复合主键。

To create the composite primary key containing ints you need to turn off `auto_increment` for the int fields:

```go
type Product struct {
    CategoryID uint64 `gorm:"primary_key;auto_increment:false"`
    TypeID     uint64 `gorm:"primary_key;auto_increment:false"`
}
```