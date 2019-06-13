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