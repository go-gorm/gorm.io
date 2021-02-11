---
title: Composite Primary Key
layout: page
---

tetapkan beberapa data sebagi kunci utama , untuk membuat composisi kunci utama, sebagai contoh:

```go
type Product struct {
  ID           string `gorm:"primaryKey"`
  LanguageCode string `gorm:"primaryKey"`
  Code         string
  Name         string
}
```

**Note** integer `PrioritizedPrimaryField` enables `AutoIncrement` by default, to disable it, you need to turn off `autoIncrement` for the int fields:

```go
type Product struct {
  CategoryID uint64 `gorm:"primaryKey;autoIncrement:false"`
  TypeID     uint64 `gorm:"primaryKey;autoIncrement:false"`
}
```
