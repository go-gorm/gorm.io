---
title: Логирование
layout: страница
---

## Логирование

Gorm имеет по умолчанию встроенную поддержку логов, он будет выводить лог, только когда есть ошибки.

```go
// Активировать логер, показать детальный лог
db.LogMode(true)

// Деактивировать логер, не показывать лог даже при ошибке
db.LogMode(false)

// отладка это одна операция, покажите детальный лог для данной возможности
db.Debug().Where("name = ?", "jinzhu").First(&User{})
```

## Настраиваемый логер

Ссылка на GORM логирование для его настройки <https://github.com/jinzhu/gorm/blob/master/logger.go>

Например, использование логера [Revel](https://revel.github.io/) для бэкенда в GORM

```go
db.SetLogger(gorm.Logger{revel.TRACE})
```

Использование `os.Stdout` как бэкэнд

```go
db.SetLogger(log.New(os.Stdout, "\r\n", 0))
```
