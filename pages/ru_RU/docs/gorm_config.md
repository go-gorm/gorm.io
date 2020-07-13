---
title: Настройки GORM
layout: страница
---

GORM предоставляет конфигурацию, которую можно использовать во время инициализации

```go
type Config struct {
    SkipDefaultTransaction bool
    NamingStrategy schema.Namer
    Logger logger.Interface
    NowFunc func() time.Time
    DryRun bool
    PrepareStmt bool
    DisableAutomaticPing bool
    DisableForeignKeyConstraintWhenMigrating bool
}
```

## SkipDefaultTransaction

GORM выполняет операции записи (создания/обновления/удаления) внутри транзакции, чтобы обеспечить целостность данных, вы можете отключить транзакции в процессе инициализации, если они не требуются

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  SkipDefaultTransaction: true,
})
```

## Стратегия именования

GORM позволяет пользователям изменять преобразование имен, переопределяя стандартный `NamingStrategy`, который должен реализовывать интерфейс `Namer`

```go
type Namer interface {
    TableName(table string) string
    ColumnName(table, column string) string
    JoinTableName(table string) string
    RelationshipFKName(Relationship) string
    CheckerName(table, column string) string
    IndexName(table, column string) string
}
```

По умолчанию `NamingStrategy` также предоставляет некоторые опции, таким образом:

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  NamingStrategy: schema.NamingStrategy{
    TablePrefix: "t_",   // table name prefix, table for `User` would be `t_users`
    SingularTable: true, // use singular table name, table for `User` would be `user` with this option enabled
  },
})
```

## Logger

Allow changes GORM's default logger by overriding this option, refer [Logger](logger.html) for more details

## NowFunc

Change the function to be used when creating a new timestamp

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  NowFunc: func() time.Time {
    return time.Now().Local()
  },
})
```

## DryRun

Generate `SQL` without executing, can be used to prepare or test generated SQL, refer [Session](session.html) for details

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DryRun: false,
})
```

## PrepareStmt

`PreparedStmt` creates a prepared statement when executing any SQL and caches them to speed up future calls, refer [Session](session.html) for details

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  PrepareStmt: false,
})
```

## DisableAutomaticPing

GORM automatically ping database after initialized to check database availability, disable it by setting it to `true`

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DisableAutomaticPing: true,
})
```

## DisableForeignKeyConstraintWhenMigrating

GORM creates database foreign key constraints automatically when `AutoMigrate` or `CreateTable`, disable this by setting it to `true`, refer [Migration](migration.html) for details

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DisableForeignKeyConstraintWhenMigrating: true,
})
```
