---
title: Logger
layout: page
---

## Logger

Gorm has built-in logger support, default mode, it will only print logs when there are errors happened.

```go
// Enable Logger, show detailed log
db.LogMode(true)

// Disable Logger, don't show any log even errors
db.LogMode(false)

// Debug a single operation, show detailed log for this operation
db.Debug().Where("name = ?", "jinzhu").First(&User{})
```

## Compatibility Mode

When you run a dialect which is not officially supported by GORM, the package will automatically print a warning message:

```
dialectXYZ is not officially supported, running under compatibility mode.
```

You can disable this message by setting to false the variable **CompatibilityWarning** like this:

```
gorm.CompatibilityWarning = false
```

## Customize Logger

Refer GORM's default logger for how to customize it [https://github.com/jinzhu/gorm/blob/master/logger.go](https://github.com/jinzhu/gorm/blob/master/logger.go)

For example, using [Revel](https://revel.github.io/)'s Logger as the backend for GORM

```go
db.SetLogger(gorm.Logger{revel.TRACE})
```

Using `os.Stdout` as the backend

```go
db.SetLogger(log.New(os.Stdout, "\r\n", 0))
```
