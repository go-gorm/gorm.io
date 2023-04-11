---
title: エラーハンドリング
layout: page
---

Goでは、エラー処理が重要です。

[Finisher Methods](method_chaining.html#finisher_method) の後にエラーチェックを行うことをおすすめします。

## Error Handling

GORMでのエラーハンドリングは、メソッドチェーン可能なAPIのため、ふつうのGoコードとは異なります。

なんらかのエラーが発生した場合、GORMは `*gorm.DB`の `Error` フィールドに設定します。以下のようにチェックする必要があります：

```go
if err := db.Where("name = ?", "jinzhu").First(&user).Error; err != nil {
  // ここでエラーハンドリング
}
```

または

```go
if result := db.Where("name = ?", "jinzhu").First(&user); result.Error != nil {
  // ここでエラーハンドリング
}
```

## ErrRecordNotFound

GORMは、`First`, `Last`, `Take`でデータの検索に失敗した場合に`ErrRecordNotFound`を返します。もし複数のエラーが発生した場合は、`errors.Is`で`ErrRecordNotFound`エラーを確認することができます。たとえば以下のように使います

```go
// RecordNotFound エラーが返却されたかチェックする
err := db.First(&user, 100).Error
errors.Is(err, gorm.ErrRecordNotFound)
```
## Dialect Translated Errors

If you would like to be able to use the dialect translated errors(like ErrDuplicatedKey), then enable the TranslateError flag when opening a db connection.

```go
db, err := gorm.Open(postgres.Open(postgresDSN), &gorm.Config{TranslateError: true})
```

## Errors

[Errors List](https://github.com/go-gorm/gorm/blob/master/errors.go)
