---
title: Logger
layout: page
---

## 日志

Gorm 有一个 [默认 logger 实现](https://github.com/go-gorm/gorm/blob/master/logger/logger.go)，默认情况下，它会打印慢 SQL 和错误

Logger 接受的选项不多，您可以在初始化时自定义它，例如：

```go
newLogger := logger.New(
  log.New(os.Stdout, "\r\n", log.LstdFlags), // io writer
  logger.Config{
    SlowThreshold:              time.Second,   // Slow SQL threshold
    LogLevel:                   logger.Silent, // Log level
    IgnoreRecordNotFoundError: true,           // Ignore ErrRecordNotFound error for logger
    ParameterizedQueries:      true,           // Don't include params in the SQL log
    Colorful:                  false,          // Disable color
  },
)

// Globally mode
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{
  Logger: newLogger,
})

// Continuous session mode
tx := db.Session(&Session{Logger: newLogger})
tx.First(&user)
tx.Model(&user).Update("Age", 18)
```

### 日志级别

GORM 定义了这些日志级别：`Silent`、`Error`、`Warn`、`Info`

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{
  Logger: logger.Default.LogMode(logger.Silent),
})
```

### Debug

Debug 单个操作，将当前操作的 log 级别调整为 logger.Info

```go
db.Debug().Where("name = ?", "jinzhu").First(&User{})
```

## 自定义 Logger

参考 GORM 的 [默认 logger](https://github.com/go-gorm/gorm/blob/master/logger/logger.go) 来定义您自己的 logger

Logger 需要实现以下接口，它接受 `context`，所以你可以用它来追踪日志

```go
type Interface interface {
    LogMode(LogLevel) Interface
    Info(context.Context, string, ...interface{})
    Warn(context.Context, string, ...interface{})
    Error(context.Context, string, ...interface{})
    Trace(ctx context.Context, begin time.Time, fc func() (sql string, rowsAffected int64), err error)
}
```
