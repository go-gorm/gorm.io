---
title: Composite Primary Key
layout: page
---

Establezca varios campos como clave primaria para habilitar la clave primaria compuesta

```go
type Product struct {
  ID           string `gorm:"primary_key"`
  LanguageCode string `gorm:"primary_key"`
  Code         string
  Name         string
}
```

Tenga en cuenta que los campos enteros con etiqueta `primary_key` son `auto_increment` por defecto. Esto puede resultar en múltiples claves primarias incrementadas automáticamente, en lugar de una única clave primaria compuesta.

Para crear la clave primaria compuesta que contiene `ints` necesita desactivar `auto_increment` para los campos int:

```go
type Product struct {
  CategoryID uint64 `gorm:"primary_key;auto_increment:false"`
  TypeID     uint64 `gorm:"primary_key;auto_increment:false"`
}
```