---
title: Chiave primaria composita
layout: page
---

Imposta più campi come chiave primaria per attivare la chiave primaria composita

```go
type Product struct {
    ID           string `gorm:"primary_key"`
    LanguageCode string `gorm:"primary_key"`
  Code         string
  Name         string
}
```