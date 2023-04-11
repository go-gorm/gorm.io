---
title: Logger
layout: page
---

## Logger

Gormには [デフォルトのLogger実装](https://github.com/go-gorm/gorm/blob/master/logger/logger.go)が入っています。デフォルトでは、スロークエリとエラーをロギングします。

デフォルトのLoggerにはいくつかの設定オプションがあり、初期化中にカスタマイズすることができます。例:

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

### ログレベル

GORMが定義しているログレベル: `Silent`, `Error`, `Warn`, `Info`

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{
  Logger: logger.Default.LogMode(logger.Silent),
})
```

### デバッグ

単一の操作をデバッグし、現在の操作のログレベルをlogger.Info に変更します

```go
db.Debug().Where("name = ?", "jinzhu").First(&User{})
```

## Loggerのカスタマイズ

独自のLoggerを定義する方法については、GORMの [default logger](https://github.com/go-gorm/gorm/blob/master/logger/logger.go) を参照してください。

Loggerは以下ののインターフェイスを実装する必要があります。 `context`を利用できるため、ログトレースで使用することができます。

```go
type Interface interface {
    LogMode(LogLevel) Interface
    Info(context.Context, string, ...interface{})
    Warn(context.Context, string, ...interface{})
    Error(context.Context, string, ...interface{})
    Trace(ctx context.Context, begin time.Time, fc func() (sql string, rowsAffected int64), err error)
}
```
