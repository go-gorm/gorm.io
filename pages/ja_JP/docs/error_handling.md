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

{% note warn %}
## Dialect Translated Errors

If you would like to be able to use the dialect translated errors(like ErrDuplicatedKey), then enable the `TranslateError` flag when opening a db connection.

```go
db, err := gorm.Open(postgres.Open(postgresDSN), &gorm.Config{TranslateError: true})
```
{% endnote %}


## ErrRecordNotFound

GORM returns `ErrRecordNotFound` when failed to find data with `First`, `Last`, `Take` (only when dialect translated errors are enabled). If there are several errors happened, you can check the `ErrRecordNotFound` error with `errors.Is`. For example,

```go
// Check if returns RecordNotFound error
err := db.First(&user, 100).Error
errors.Is(err, gorm.ErrRecordNotFound)
```
## Errors

[Errors List](https://github.com/go-gorm/gorm/blob/master/errors.go)
