---
title: 复合主键
layout: page
---

通过将多个字段设为主键，以创建复合主键，例如：

```go
type Product struct {
  ID           string `gorm:"primaryKey"`
  LanguageCode string `gorm:"primaryKey"`
  Code         string
  Name         string
}
```

**注意：**默认情况下，整形 `PrioritizedPrimaryField` 启用了 `AutoIncrement`，要禁用它，您需要为整形字段关闭 `autoIncrement`：

```go
type Product struct {
  CategoryID uint64 `gorm:"primaryKey;autoIncrement:false"`
  TypeID     uint64 `gorm:"primaryKey;autoIncrement:false"`
}
```
