---
title: Clé primaire composée
layout: page
---

Définir plusieurs champs comme clé primaire pour activer la clé primaire composée

```go
type Product struct {
    ID           string `gorm:"primary_key"`
    LanguageCode string `gorm:"primary_key"`
  Code         string
  Name         string
}
```