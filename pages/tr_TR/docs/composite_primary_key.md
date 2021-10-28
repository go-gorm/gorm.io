---
title: Bileşik Birincil Anahtar
layout: sayfa
---

Birden fazla birincil anahtar oluşturmak birleşik birincil anahtar oluşturur, örnek olarak:

```go
type Product struct {
  ID           string `gorm:"primaryKey"`
  LanguageCode string `gorm:"primaryKey"`
  Code         string
  Name         string
}
```

**Not** Sayısal `BirlesikBirincilAlan` başlangıç olarak `AutoIncrement(OtomatikArtan)` gelir, bunu kapatmak için `autoIncrement` alanını kapatmalısınız:

```go
type Product struct {
  CategoryID uint64 `gorm:"primaryKey;autoIncrement:false"`
  TypeID     uint64 `gorm:"primaryKey;autoIncrement:false"`
}
```
