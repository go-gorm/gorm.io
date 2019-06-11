---
title: Составной первичный ключ
layout: страница
---

Установите несколько полей как первичный ключ для включения композитного первичного ключа

```go
type Product struct {
    ID           string `gorm:"primary_key"`
    LanguageCode string `gorm:"primary_key"`
  Code         string
  Name         string
}
```
