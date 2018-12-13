---
title: エラーハンドリング
layout: page
---
Goではエラーハンドリングが重要です。

[即時メソッド](/docs/method_chaining.html#Immediate-Methods)の後ではエラーチェックを行ったほうが良いです。

## エラーハンドリング

GORMにおけるエラーハンドリングは慣用的なGoのコードとは少し異なります。チェーン可能なAPIなためですが、それでもエラーハンドリングはとても簡単です。

If there are any error happened, GORM will set it to `*gorm.DB`'s `Error` field, you could check it like this:

```go
if err := db.Where("name = ?", "jinzhu").First(&user).Error; err != nil {
    // エラーハンドリング...
}
```

もしくは

```go
if result := db.Where("name = ?", "jinzhu").First(&user); result.Error != nil {
    // エラーハンドリング...
}
```

## エラー

It is common several errors happened during processing data, GORM provides an API to return all happened errors as a slice

```go
// 1つ以上のエラーが起きた場合、`GetErrors`は`[]error`を返します
db.First(&user).Limit(10).Find(&users).GetErrors()

fmt.Println(len(errors))

for _, err := range errors {
  fmt.Println(err)
}
```

## RecordNotFoundエラー

GORMは`RecordNotFound`エラーを扱うためのショートカットを提供しており、複数のエラーが生じた場合はその中に`RecordNotFound`エラーが含まれているかチェックします。

```go
// RecordNotFoundエラーを返すかチェックします
db.Where("name = ?", "hello world").First(&user).RecordNotFound()

if db.Model(&user).Related(&credit_card).RecordNotFound() {
  // レコードが見つかりません
}

if err := db.Where("name = ?", "jinzhu").First(&user).Error; gorm.IsRecordNotFoundError(err) {
  // レコードが見つかりません
}
```