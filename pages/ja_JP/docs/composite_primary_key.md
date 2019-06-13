---
title: Composite Primary Key
layout: page
---

複数のフィールドに primary key を指定すると composite primary key (複合主キー)にすることができます

```go
type Product struct {
    ID           string `gorm:"primary_key"`
    LanguageCode string `gorm:"primary_key"`
  Code         string
  Name         string
}
```