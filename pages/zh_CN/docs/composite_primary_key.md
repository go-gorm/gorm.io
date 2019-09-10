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