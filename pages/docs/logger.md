---
title: Logger
layout: page
---

## Logger

Gorm has a [default logger implementation](https://github.com/go-gorm/gorm/blob/master/logger/logger.go), it will prints Slow SQL and happening errors by default

The logger accepts few options, you can customize it during initialization, for example:

```go
newLogger := logger.New(
  log.New(os.Stdout, "\r\n", log.LstdFlags), // io writer
  logger.Config{
    SlowThreshold: time.Second,   // Slow SQL threshold
    LogLevel:      logger.Silent, // Log level
    Colorful:      false,         // Disable color
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

// Debug a single operation, change the session's log level to logger.Info
db.Debug().Where("name = ?", "jinzhu").First(&User{})
```

### Log Levels

GORM defined log levels: `Silent`, `Error`, `Warn`, `Info`

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{
  Logger: logger.Default.LogMode(logger.Silent),
})
```

## Customize Logger

Refer GORM's [default logger](https://github.com/go-gorm/gorm/blob/master/logger/logger.go) for how to define your own one

The logger needs to implement the following interface, it accepts `context`, so you can use it for log tracing

```go
type Interface interface {
	LogMode(LogLevel) Interface
	Info(context.Context, string, ...interface{})
	Warn(context.Context, string, ...interface{})
	Error(context.Context, string, ...interface{})
	Trace(ctx context.Context, begin time.Time, fc func() (string, int64), err error)
}
```
