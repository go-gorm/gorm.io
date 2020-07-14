---
title: Композитный первичный ключ
layout: страница
---

Установить несколько полей как основной ключ для создания составного первичного ключа, например:

```go
type Product struct {
  ID           string `gorm:"primaryKey"`
  LanguageCode string `gorm:"primaryKey"`
  Code         string
  Name         string
}
```

**Примечание** integer `PrioritizedPrimaryField` включает `AutoIncrement` по умолчанию, чтобы отключить его, вам нужно выключить `autoIncrement` для полей:

```go
type Product struct {
  CategoryID uint64 `gorm:"primaryKey;autoIncrement:false"`
  TypeID     uint64 `gorm:"primaryKey;autoIncrement:false"`
}
```
