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

### Tingkat log

Level log yang ditentukan GORM: `Silent`, `Error`, `Warn`, `Info`

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{
  Logger: logger.Default.LogMode(logger.Silent),
})
```

### Debug

Debug satu operasi, ubah level log operasi saat ini menjadi logger.Info

```go
db.Debug().Where("name = ?", "jinzhu").First(&User{})
```

## Customize Logger

Lihat ke GORM [default logger](https://github.com/go-gorm/gorm/blob/master/logger/logger.go) untuk cara mendefinisikan milik Anda sendiri

Logger perlu mengimplementasikan interface berikut, ia menerima `context`, sehingga Anda bisa menggunakannya untuk log tracing

```go
type Interface interface {
    LogMode(LogLevel) Interface
    Info(context.Context, string, ...interface{})
    Warn(context.Context, string, ...interface{})
    Error(context.Context, string, ...interface{})
    Trace(ctx context.Context, begin time.Time, fc func() (sql string, rowsAffected int64), err error)
}
```
