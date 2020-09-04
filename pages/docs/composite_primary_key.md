---
title: Composite Primary Key
layout: page
---

Set multiple fields as primary key creates composite primary key, for example:

```go
type Product struct {
  ID           string `gorm:"primary_key"`
  LanguageCode string `gorm:"primary_key"`
  Code         string
  Name         string
}
```

**Note** integer `PrioritizedPrimaryField` enables `AutoIncrement` by default, to disable it, you need to turn off `auto_increment` for the int fields:

```go
type Product struct {
  CategoryID uint64 `gorm:"primary_key;auto_increment:false"`
  TypeID     uint64 `gorm:"primary_key;auto_increment:false"`
}
```
