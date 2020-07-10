---
title: Logger
layout: page
---

## Logger

Gorm has a [default logger implementation](https://github.com/go-gorm/gorm/blob/master/logger/logger.go), it will print Slow SQL and happening errors by default

The logger accepts few options, you can customize it during initialization, for example:

```go
db, err := gorm. Open(sqlite. Open("test.db"), &gorm. Config{
  Logger: logger. Default. LogMode(logger. Silent),
})
```

### Log Levels

GORM defined log levels: `Silent`, `Error`, `Warn`, `Info`

```go
db, err := gorm. Open(sqlite. Open("test.db"), &gorm. Config{
  Logger: logger. Default. LogMode(logger. Silent),
})
```

## Customize Logger

Refer to GORM's [default logger](https://github.com/go-gorm/gorm/blob/master/logger/logger.go) for how to define your own one

The logger needs to implement the following interface, it accepts `context`, so you can use it for log tracing

```go
type Interface interface {
    LogMode(LogLevel) Interface
    Info(context. Context, string, ...interface{})
    Warn(context. Context, string, ...interface{})
    Error(context. Context, string, ...interface{})
    Trace(ctx context. Context, begin time. Time, fc func() (string, int64), err error)
}
```
