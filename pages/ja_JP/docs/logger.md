---
title: ロガー
layout: page
---

## ロガー

Gormは [デフォルトのロガー実装](https://github.com/go-gorm/gorm/blob/master/logger/logger.go)を持っています。デフォルトでは、遅いSQLとエラーをロギングします。

ロガーはいくつかのオプションを受け付けます。初期化中にカスタマイズできます。例:

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

### ログレベル

GORMが定義しているログレベル: `Silent`, `Error`, `Warn`, `Info`

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{
  Logger: logger.Default.LogMode(logger.Silent),
})
```

## ロガーのカスタマイズ

独自のロガーを定義する方法については、GORMの [デフォルトロガー](https://github.com/go-gorm/gorm/blob/master/logger/logger.go) を参照してください。

ロガーは次のインターフェイスを実装する必要があります。 `context`を受け付けるため、ログトレースに使用できます。

```go
type Interface interface {
    LogMode(LogLevel) Interface
    Info(context.Context, string, ...interface{})
    Warn(context.Context, string, ...interface{})
    Error(context.Context, string, ...interface{})
    Trace(ctx context.Context, begin time.Time, fc func() (string, int64), err error)
}
```
