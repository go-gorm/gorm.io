---
title: 복합키
layout: page
---

Set multiple fields as primary key creates composite primary key, for example:

```go
type Product struct {
  ID           string `gorm:"primaryKey"`
  LanguageCode string `gorm:"primaryKey"`
  Code         string
  Name         string
}
```

**주의** 정수 타입의 `PrioritizedPrimaryField (기본키) `는 기본적으로 `AutoIncrement` 을 지원합니다. 이것을 비활성화하려면, 해당 int 필드의 자동 증가 옵션을 해제해야 합니다.

```go
type Product struct {
  CategoryID uint64 `gorm:"primaryKey;autoIncrement:false"`
  TypeID     uint64 `gorm:"primaryKey;autoIncrement:false"`
}
```
