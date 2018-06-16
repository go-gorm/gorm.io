---
title: Composite Primary Key
layout: page
---

Set multiple fields as primary key to enable composite primary key

```go
type Product struct {
	ID           string `gorm:"primary_key"`
	LanguageCode string `gorm:"primary_key;auto_increment:false"`
  Code         string
  Name         string
}
```


