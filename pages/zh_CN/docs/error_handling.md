---
title: 处理错误
layout: page
---

在 Go 中，处理错误是很重要的。

我们鼓励您在调用任何 [Finisher 方法](https://github.com/go-gorm/gorm/blob/master/finisher_api.go) 后，都进行错误检查

## 处理错误

GORM 的错误处理与常见的 Go 代码不同，因为 GORM 提供的是链式 API。

如果遇到任何错误，GORM 会设置 `*gorm.DB` 的 `Error` 字段，您需要像这样检查它：

```go
if err := db.Where("name = ?", "jinzhu").First(&user).Error; err != nil {
  // 处理错误...
}
```

或者

```go
if result := db.Where("name = ?", "jinzhu").First(&user); result.Error != nil {
  // 处理错误...
}
```

## ErrRecordNotFound

GORM returns `ErrRecordNotFound` when failed to find data with `First`, `Last`, `Take`, if there are several errors happened, you can check the `ErrRecordNotFound` error with `errors.Is`, for example:

```go
// Check if returns RecordNotFound error
err := db.First(&user, 100).Error
errors.Is(tx.Error, ErrRecordNotFound)
```

## Errors

[Errors List](https://github.com/go-gorm/gorm/blob/master/errors.go)
