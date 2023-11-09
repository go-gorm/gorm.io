---
title: Обработка ошибок
layout: страница
---

В Go, очень важна обработка ошибок.

Вам рекомендуется проверять ошибки после [Методов окончания](method_chaining.html#finisher_method)

## Обработка ошибок

Обработка ошибок в GORM отличается от идиоматического Go кода из-за цепного API.

Если возникнет ошибка, GORM заполнит поле `*gorm.DB` `Error`, его необходимо проверять следующим образом:

```go
if err := db.Where("name = ?", "jinzhu").First(&user).Error; err != nil {
  // обработка ошибок ...
}
```

или

```go
if result := db.Where("name = ?", "jinzhu").First(&user); result.Error != nil {
  // обработка ошибок ...
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
## Ошибки

[Errors List](https://github.com/go-gorm/gorm/blob/master/errors.go)
