---
title: Kunci Utama Komposit
layout: page
---

Menetapkan beberapa bidang sebagai kunci utama untuk memungkinkan kunci utama komposit

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