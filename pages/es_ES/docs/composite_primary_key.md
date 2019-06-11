---
title: Composite Primary Key
layout: page
---

Establezca varios campos como clave primaria para habilitar la clave primaria compuesta

```go
type Product struct {     ID string `gorm:"primary_key"`     LanguageCode string `gorm:"primary_key"`   Code string   Name string }
```
