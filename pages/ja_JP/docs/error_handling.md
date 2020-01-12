---
title: エラーハンドリング
layout: page
---

Goではエラーハンドリングが重要です。

You are encouraged to do error check after any [Immediate Methods](method_chaining.html#Immediate-Methods)

## エラーハンドリング

GORMにおけるエラーハンドリングは、チェーン可能なAPIのために、慣用的なGoのコードとは少し異なります。ですが、実装は簡単です。

何らかのエラーが起きた場合、GORMはそれを`*gorm.DB`の`Error`フィールドにセットするので、このようにチェックを行うことができます:

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

データを処理するときに、複数のエラーが発生するのはよくあることです。GORMはエラーをスライスとしてreturnするAPIを提供しています。

```go
// 1つ以上のエラーが起きた場合、`GetErrors`は`[]error`を返します
errors := db.First(&user).Limit(10).Find(&users).GetErrors()

fmt.Println(len(errors))

for _, err := range errors {
  fmt.Println(err)
}
```

## RecordNotFoundエラー

GORMは`RecordNotFound`エラーを扱うためのショートカットを提供しています。複数のエラーが生じた場合は、その中に`RecordNotFound`エラーが含まれているかチェックします。

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