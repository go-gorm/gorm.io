title: Logger
---

Gorm has built-in logger support, by default, it will print happened errors

```go
// Enable Logger, show detailed log
db.LogMode(true)

// Disable Logger, don't show any log
db.LogMode(false)

// Debug a single operation, show detailed log for this operation
db.Debug().Where("name = ?", "jinzhu").First(&User{})
```

#### Customize Logger

Refer GORM's default logger for how to customize it [https://github.com/jinzhu/gorm/blob/master/logger.go](https://github.com/jinzhu/gorm/blob/master/logger.go)

```go
db.SetLogger(gorm.Logger{revel.TRACE})
db.SetLogger(log.New(os.Stdout, "\r\n", 0))
```
