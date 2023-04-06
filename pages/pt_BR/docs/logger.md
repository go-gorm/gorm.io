---
title: Logger
layout: page
---

## Logger

O GORM tem uma [ implementação padrão de logger](https://github.com/go-gorm/gorm/blob/master/logger/logger.go), ele irá exibir, por padrão,  as consultas SQL mais demoradas e erros que possam acontecer.

O logger aceita poucas opções, você pode personalizá-lo durante a inicialização, por exemplo:

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

### Níveis de Log

O GORM tem definido os níveis de log: `Silent`, `Error`, `Warn`, `Info`

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{
  Logger: logger.Default.LogMode(logger.Silent),
})
```

### Debug

Para debuggar uma única operação, alterar o nível de log da operação atual para logger.Info

```go
db.Debug().Where("name = ?", "jinzhu").First(&User{})
```

## Personalizar Logger

Consulte o [logger padrão](https://github.com/go-gorm/gorm/blob/master/logger/logger.go) do GORM para definir o seu próprio

O logger precisa implementar a seguinte interface, ele aceita `context`, para que você possa usá-lo para rastreamento de log

```go
type Interface interface {
    LogMode(LogLevel) Interface
    Info(context.Context, string, ...interface{})
    Warn(context.Context, string, ...interface{})
    Error(context.Context, string, ...interface{})
    Trace(ctx context.Context, begin time.Time, fc func() (sql string, rowsAffected int64), err error)
}
```
