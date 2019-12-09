---
title: 复合主键
layout: page
---

将多个字段设置为 primary key 以启用复合主键

```go
type Product struct {
   ID           string `gorm:"primary_key"`
   LanguageCode string `gorm:"primary_key"`
   Code         string
   Name         string
}
```

请注意，默认情况下，带有 `主键` 标签的整型字段的会 `auto_increment`。 这可能会导致存在多个自动增长的整型主键，而不是单个复合主键。

想要创建包含多个整型的复合主键，你需要为这些整型字段关闭 `auto_increment`：

```go
type Product struct {
    CategoryID uint64 `gorm:"primary_key;auto_increment:false"`
    TypeID     uint64 `gorm:"primary_key;auto_increment:false"`
}
```