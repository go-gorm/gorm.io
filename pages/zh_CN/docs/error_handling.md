---
title: 处理错误
layout: page
---

在 Go 中，处理错误是很重要的。

我们鼓励您在调用任何 [Finisher 方法](method_chaining.html#finisher_method) 后，都进行错误检查

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

当 `First`、`Last`、`Take` 方法找不到记录时，GORM 会返回 `ErrRecordNotFound` 错误。如果发生了多个错误，你可以通过 `errors.Is` 判断错误是否为 `ErrRecordNotFound`，例如：

```go
// 检查错误是否为 RecordNotFound
err := db.First(&user, 100).Error
errors.Is(err, gorm.ErrRecordNotFound)
```
## 翻译方言错误

如果您希望将数据库的方言错误转换为gorm的错误类型（例如将MySQL中的“Duplicate entry”转换为ErrDuplicatedKey），则在打开数据库连接时启用TranslateError标志。

```go
db, err := gorm.Open(postgres.Open(postgresDSN), &gorm.Config{TranslateError: true})
```

## Errors

[Errors List](https://github.com/go-gorm/gorm/blob/master/errors.go)
