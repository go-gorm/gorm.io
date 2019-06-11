---
title: 错误处理
layout: 页面
---

Go的錯誤處理是很重要的

建議您在任何立即方法后进行错误检查

## 错误处理

GORM中的错误处理与惯用的Go代码不同，因为它具有可链接的API，但仍然易于实现。

如果发生任何错误，GORM将设置* gorm.DB的错误字段，可以这样检查：

```go
if err := db.Where("name = ?", "jinzhu").First(&user).Error; err != nil {
    // error handling...
}
```

Or

```go
if result := db.Where("name = ?", "jinzhu").First(&user); result.Error != nil {
    // error handling...
}
```

## 错误

处理数据时，通常会发生多个错误。 GORM提供了一个API来将所有错误作为切片返回：

```go
// If there are more than one error happened, `GetErrors` returns them as `[]error`
errors := db.First(&user).Limit(10).Find(&users).GetErrors()

fmt.Println(len(errors))

for _, err := range errors {
  fmt.Println(err)
}
```

## RecordNotFound（紀錄未找到）错误

GORM提供了处理RecordNotFound错误的快捷方式。如果有多个错误，它将检查它们中是否有任何RecordNotFound错误。

```go
// Check if returns RecordNotFound error
db.Where("name = ?", "hello world").First(&user).RecordNotFound()

if db.Model(&user).Related(&credit_card).RecordNotFound() {
  // record not found
}

if err := db.Where("name = ?", "jinzhu").First(&user).Error; gorm.IsRecordNotFoundError(err) {
  // record not found
}
```
