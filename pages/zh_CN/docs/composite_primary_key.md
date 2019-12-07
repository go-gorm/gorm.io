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

Note that integer fields with `primary_key` tag are `auto_increment` by default. That can result in multiple auto-incremented integer primary keys instead of a single composite primary key.

To create the composite primary key containing ints you need to turn off `auto_increment` for the int fields:

```go
type Product struct {
    CategoryID uint64 `gorm:"primary_key;auto_increment:false"`
    TypeID     uint64 `gorm:"primary_key;auto_increment:false"`
}
```