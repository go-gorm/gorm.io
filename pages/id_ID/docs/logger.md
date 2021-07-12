---
title: Logger
layout: halaman
---

## Logger

Gorm mempunyai sebuah [implementasi awal logger](https://github.com/go-gorm/gorm/blob/master/logger/logger.go), dimana akan mencetak Slow SQL dan mencetak kesalahan saat terjadi kesalahan

Logger menerima banyak opsi, anda dapat menyesuaikannya disaat inisialisasi, misalnya:

```go
newLogger := logger.New(
  log.New(os.Stdout, "\r\n", log.LstdFlags), // io writer
  logger.Config{
    SlowThreshold:              time.Second,   // ambang Slow SQL
    LogLevel:                   logger.Silent, // tingkat Log
    IgnoreRecordNotFoundError: true,           // mengabaikan kesalahan ErrRecordNotFound  untuk logger
    Colorful:                  false,          // nonaktifkan warna
  },
)

// Mode global
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{
  Logger: newLogger,
})

// Mode sesi berkelanjutan
tx := db.Session(&Session{Logger: newLogger})
tx.First(&user)
tx.Model(&user).Update("Age", 18)
```

### Tingkat log

GORM defined log levels: `Silent`, `Error`, `Warn`, `Info`

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

## Customize Logger

Refer to GORM's [default logger](https://github.com/go-gorm/gorm/blob/master/logger/logger.go) for how to define your own one

The logger needs to implement the following interface, it accepts `context`, so you can use it for log tracing

```go
type Interface interface {
    LogMode(LogLevel) Interface
    Info(context.Context, string, ...interface{})
    Warn(context.Context, string, ...interface{})
    Error(context.Context, string, ...interface{})
    Trace(ctx context.Context, begin time.Time, fc func() (sql string, rowsAffected int64), err error)
}
```
