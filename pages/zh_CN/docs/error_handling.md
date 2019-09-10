---
title: 错误处理
layout: page
---

Go的错误处理是很重要的

建议您在调用任何 [立即执行方法](https://gorm. io/zh_CN/docs/method_chaining. html#Immediate-Methods) 后进行错误检查

## 错误处理

GORM中的错误处理与惯用的Go代码不同，因为它具有可链接的API，但仍然易于实现。

如果发生任何错误，GORM将设置* gorm.DB的错误字段，可以这样检查：

```go
if err := db.Where("name = ?", "jinzhu").First(&user).Error; err != nil {
    // 处理错误……
}
```

或者

```go
if result := db.Where("name = ?", "jinzhu").First(&user); result.Error != nil {
    // 处理错误……
}
```

## 错误

处理数据时，通常会发生多个错误。 GORM提供了一个API来将所有错误作为切片返回：

```go
// 如果发生了一个以上的错误， `GetErrors` 以`[]error`形式返回他们
errors := db.First(&user).Limit(10).Find(&users).GetErrors()

fmt.Println(len(errors))

for _, err := range errors {
  fmt.Println(err)
}
```

## 记录未找到错误

RecordNotFound，GORM提供了处理 `RecordNotFound` 错误的快捷方式。如果有多个错误，它将逐一检查这些错误是否为 `RecordNotFound` 错误。

```go
// 检查是否为 RecordNotFound 错误
db.Where("name = ?", "hello world").First(&user).RecordNotFound()

if db.Model(&user).Related(&credit_card).RecordNotFound() {
  // 未找到记录
}

if err := db.Where("name = ?", "jinzhu").First(&user).Error; gorm.IsRecordNotFoundError(err) {
  // 未找到记录
}
```