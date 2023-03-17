---
title: Llave primaria compuesta
layout: page
---

Establecer múltiples campos como llave primaria crea una llave primaria compuesta, por ejemplo:

```go
type Product struct {
  ID           string `gorm:"primaryKey"`
  LanguageCode string `gorm:"primaryKey"`
  Code         string
  Name         string
}
```

**Nota** entero `PrioritizedPrimaryField` habilita `AutoIncrement` por defecto, para deshabilitarlo, necesita desactivar `autoIncremento` para los campos int:

```go
type Product struct {
  CategoryID uint64 `gorm:"primaryKey;autoIncrement:false"`
  TypeID     uint64 `gorm:"primaryKey;autoIncrement:false"`
}
```
