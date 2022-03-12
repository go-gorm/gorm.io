---
title: Chave Primária Composta
layout: page
---

Definir vários campos como a chave primária cria chave primária composta, por exemplo:

```go
type Product struct {
  ID           string `gorm:"primaryKey"`
  LanguageCode string `gorm:"primaryKey"`
  Code         string
  Name         string
}
```

**Note** que o inteiro `PrioritizedPrimaryField` habilita o  `AutoIncrement` por padrão, para desativá-lo, você precisa desabilitar o `autoIncrement` para os campos de inserção:

```go
type Product struct {
  CategoryID uint64 `gorm:"primaryKey;autoIncrement:false"`
  TypeID     uint64 `gorm:"primaryKey;autoIncrement:false"`
}
```
