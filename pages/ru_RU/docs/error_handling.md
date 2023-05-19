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

## ErrRecordNotFound

GORM возвращает `ErrRecordNotFound`, когда не удалось найти данные при помощи `First`, `Last`, `Take`, если произошло несколько ошибок, вы можете проверить `ErrRecordNotFound` при помощи `errors.Is`, например:

```go
// Проверка возвращается ли ошибка RecordNotFound
err := db.First(&user, 100).Error
errors.Is(err, gorm.ErrRecordNotFound)
```
## Dialect Translated Errors

Если вы хотите иметь возможность использовать ошибки перевода диалекта (например, ErrDuplicatedKey), то включите флаг TranslateError при открытии подключения к базе данных.

```go
db, err := gorm.Open(postgres.Open(postgresDSN), &gorm.Config{TranslateError: true})
```

## Ошибки

[Список ошибок](https://github.com/go-gorm/gorm/blob/master/errors.go)
