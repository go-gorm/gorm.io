---
title: Clé primaire composite
layout: page
---

Définir plusieurs champs comme clé primaire crée une clé primaire composite, par exemple :

```go
type Product struct {
  ID string `gorm:"primaryKey"`
  LanguageCode string `gorm:"primaryKey"`
  Code string
  Name string
}
```

**Note**integer `PrioritizedPrimaryField` active `Auto-Increment` par défaut, pour le désactiver, vous devez désactiver `autoIncrement` pour les champs int :

```go
type Product struct {
  CategoryID uint64 `gorm:"primaryKey;autoIncrement:false"`
  TypeID     uint64 `gorm:"primaryKey;autoIncrement:false"`
}
```
