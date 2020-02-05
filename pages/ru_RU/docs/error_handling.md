---
title: Обработка ошибок
layout: страница
---

В Go важное значение имеет обработка ошибок.

Вам рекомендуется проверить ошибки после любого из [Быстрых методов](method_chaining.html#Immediate-Methods)

## Обработка ошибок

Ошибка обработки в GORM отличается от идиоматического кода Go из-за его разделенного API, но его все еще легко реализовать.

Если возникла ошибка, GORM установит `*gorm.DB` `Error`, которое вы можете проверить следующим образом:

```go
if err := db.Where("name = ?", "jinzhu").First(&user).Error; err != nil {
  // error handling...
}
```

Или

```go
if result := db.Where("name = ?", "jinzhu").First(&user); result.Error != nil {
  // error handling...
}
```

## Ошибки

При обработке данных, часто встречаются несколько ошибок. GORM предоставляет API для возврата всех ошибок в виде среза:

```go
// Если перехвачено более одной ошибки, `GetErrors` возвращает их как `[]error`
errors := db.First(&user).Limit(10).Find(&users).GetErrors()

fmt.Println(len(errors))

for _, err := range errors {
  fmt.Println(err)
}
```

## RecordNotFound ошибка

GORM предоставляет ярлык для обработки ошибок `RecordNotFound`. Если есть несколько ошибок, то он проверяет, является ли какой-либо из них ошибкой `RecordNotFound`.

```go
// Проверяет если вернулась RecordNotFound ошибка
db.Where("name = ?", "hello world").First(&user).RecordNotFound()

if db.Model(&user).Related(&credit_card).RecordNotFound() {
  // запись не найдена
}

if err := db.Where("name = ?", "jinzhu").First(&user).Error; gorm.IsRecordNotFoundError(err) {
  // запись не найдена
}
```