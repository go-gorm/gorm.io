---
title: Настройки GORM
layout: страница
---

GORM предоставляет конфигурацию, которую можно использовать во время инициализации

```go
type Config struct {
  SkipDefaultTransaction bool
  NamingStrategy         schema.Namer
  Logger                 logger.Interface
  NowFunc                func() time.Time
  DryRun                 bool
  PrepareStmt            bool
  AllowGlobalUpdate      bool
  DisableAutomaticPing   bool
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

## <span id="naming_strategy">NamingStrategy</span>

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
    TablePrefix: "t_",   // префикс имен таблиц, таблица для `User` будет `t_users`
    SingularTable: true, // использовать именование в единственном числе, таблица для `User` будет `user` при включении этой опции, или `t_user` при TablePrefix = "t_"
  },
})
```

## Logger

Разрешены изменения логирования по умолчанию в GORM, переопределяя эту опцию, смотрите [Logger](logger.html) для получения более подробной информации

## <span id="now_func">NowFunc</span>

Изменить функцию, используемую при создании новой отметки времени

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  NowFunc: func() time.Time {
    return time.Now().Local()
  },
})
```

## DryRun

Генерировать `SQL` без выполнения, может быть использован для подготовки или тестирования SQL, смотрите [Сессии](session.html) для подробностей

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DryRun: false,
})
```

## PrepareStmt

`PreparedStmt (подготовка stmt)` создает подготовленную операцию при выполнении любого SQL и кэширует ее для ускорения будущих запросов, смотрите [Сессии](session.html) для подробностей

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  PrepareStmt: false,
})
```

## AllowGlobalUpdate

Включение глобального обновления/удаления, смотрите [сессии](session.html) для подробностей

## DisableAutomaticPing

GORM автоматически опрашивает базу данных после инициализации для проверки доступности базы данных, отключается установкой в `true`

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DisableAutomaticPing: true,
})
```

## DisableForeignKeyConstraintWhenMigrating

GORM создает ограничения внешних ключей автоматически, когда `AutoMigrate (авто миграция)` или `CreateTable (создание таблицы)`, отключите это, установив `true`, смотрите [Миграции](migration.html) для подробностей

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DisableForeignKeyConstraintWhenMigrating: true,
})
```
