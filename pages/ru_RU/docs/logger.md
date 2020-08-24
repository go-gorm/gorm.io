---
title: Logger
layout: страница
---

## Logger

Gorm реализует [логгер по умолчанию](https://github.com/go-gorm/gorm/blob/master/logger/logger.go), он будет выводить Медленные SQL запросы и перехватывать ошибки

Логгер принимает несколько опций, вы можете настроить их в процессе инициализации, например:

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
```

### Уровни лога

Уровни логирования GORM: `Silent`, `Error`, `Warn`, `Info`

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{
  Logger: logger.Default.LogMode(logger.Silent),
})
```

### Debug

Debug a single operation, change current operation's log level to logger.Info

```go
db.Debug().Where("name = ?", "jinzhu").First(&User{})
```

## Настройка логгера

Refer to GORM's [default logger](https://github.com/go-gorm/gorm/blob/master/logger/logger.go) for how to define your own one

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
