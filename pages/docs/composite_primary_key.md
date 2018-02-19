---
title: Composite Primary Key
layout: page
---

Set multiple fields as primary key to enable composite primary key

```go
type Product struct {
	ID           string `gorm:"primary_key"`
	LanguageCode string `gorm:"primary_key"`
  Code         string
  Name         string
}
```


