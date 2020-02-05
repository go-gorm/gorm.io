---
title: Составной первичный ключ
layout: страница
---

Установите несколько полей как первичный ключ для включения композитного первичного ключа

```go
type Product struct {
  ID           string `gorm:"primary_key"`
  LanguageCode string `gorm:"primary_key"`
  Code         string
  Name         string
}
```

Обратите внимание, что поля типа int с тегом `primary_key` являются `auto_increment` по умолчанию. Это может привести к множеству автоматического увеличения целого числа первичных ключей вместо одного составного первичного ключа.

Для создания первичного композитного ключа, содержащего числа, необходимо выключить `auto_increment` для int полей:

```go
type Product struct {
  CategoryID uint64 `gorm:"primary_key;auto_increment:false"`
  TypeID     uint64 `gorm:"primary_key;auto_increment:false"`
}
```