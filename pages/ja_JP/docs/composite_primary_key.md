---
title: 複合主キー
layout: page
---

複数のフィールドを主キーとして設定すると、次のように複合主キーが作成されます。

```go
type Product struct {
  ID           string `gorm:"primaryKey"`
  LanguageCode string `gorm:"primaryKey"`
  Code         string
  Name         string
}
```

**注** intの`PrioritizedPrimaryField`はデフォルトで`AutoIncrement`されます。 無効にしたいなら、`autoIncrement`をintフィールドでfalseにしてください。

```go
type Product struct {
  CategoryID uint64 `gorm:"primaryKey;autoIncrement:false"`
  TypeID     uint64 `gorm:"primaryKey;autoIncrement:false"`
}
```
