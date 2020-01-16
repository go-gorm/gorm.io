---
title: Chiave primaria composta
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

Nota che i campi integer con il tag `primary_key` sono `auto_increment` di default. Questo può risultare in più chiavi primarie integer auto-increment invece di una singola chiave primaria composta.

To create the composite primary key containing ints you need to turn off `auto_increment` for the int fields:

```go
type Product struct {
  CategoryID uint64 `gorm:"primary_key;auto_increment:false"`
  TypeID     uint64 `gorm:"primary_key;auto_increment:false"`
}
```