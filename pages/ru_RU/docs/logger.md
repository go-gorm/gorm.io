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
    SlowThreshold: time.Second,   // Временной зазор определения медленных запросов SQL
    LogLevel:      logger.Silent, // Уровень логирования
    Colorful:      false,         // Отключить цвета
  },
)

// Глобальный режим
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{
  Logger: newLogger,
})

// Сессионный режим
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

### Отладка

Отладка одиночной операции, изменить уровень журнала текущей операции на logger.Info

```go
db.Debug().Where("name = ?", "jinzhu").First(&User{})
```

## Настройка логгера

Смотрите [ логирование по умолчанию](https://github.com/go-gorm/gorm/blob/master/logger/logger.go) для определения своего собственного

Логгер должен реализовать следующий интерфейс, он принимает `context`, чтобы вы могли использовать его для отслеживания журнала

```go
type Interface interface {
    LogMode(LogLevel) Interface
    Info(context.Context, string, ...interface{})
    Warn(context.Context, string, ...interface{})
    Error(context.Context, string, ...interface{})
    Trace(ctx context.Context, begin time.Time, fc func() (string, int64), err error)
}
```
