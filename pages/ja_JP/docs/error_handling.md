---
title: エラーハンドリング
layout: page
---

Goでは、エラー処理が重要です。

[即時メソッド](https://github.com/go-gorm/gorm/blob/master/finisher_api.go) の後にエラーチェックを行うことをおすすめします。

## エラーハンドリング

GORMでのエラーハンドリングは、メソッドチェーン可能なAPIのため、ふつうのGoコードとは異なります。

If any error occurs, GORM will set `*gorm.DB`'s `Error` field, you need to check it like this:

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

## ErrRecordNotFound

GORM returns `ErrRecordNotFound` when failed to find data with `First`, `Last`, `Take`, if there are several errors happened, you can check the `ErrRecordNotFound` error with `errors.Is`, for example:

```go
// Check if returns RecordNotFound error
err := db.First(&user, 100).Error
errors.Is(tx.Error, ErrRecordNotFound)
```

## Errors

[Errors List](https://github.com/go-gorm/gorm/blob/master/errors.go)
