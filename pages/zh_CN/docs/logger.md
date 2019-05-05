---
title: Logger
layout: page
---

## Logger

Gorm有内置的日志记录器支持，默认情况下，它会打印发生的错误

```go
// 启用Logger，显示详细日志
db.LogMode(true)

// 禁用日志记录器，不显示任何日志
db.LogMode(false)

// 调试单个操作，显示此操作的详细日志
db.Debug().Where("name = ?", "jinzhu").First(&User{})
```

## 自定义 Logger

参考GORM的默认记录器如何自定义它 <https://github.com/jinzhu/gorm/blob/master/logger.go>

例如，使用[Revel](https://revel.github.io/)的Logger作为GORM的输出

```go
db.SetLogger(gorm.Logger{revel.TRACE})
```

使用 `os.Stdout` 作为输出

```go
db.SetLogger(log.New(os.Stdout, "\r\n", 0))
```