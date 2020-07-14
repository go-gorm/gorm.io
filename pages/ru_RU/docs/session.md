---
title: Сессия
layout: страница
---

GORM предоставляет методы `Session`, которые являются [`Методами новой сессии`](method_chaining.html), и позволяют создавать новый режим сеанса с настройками:

```go
// Настройки Session
type Session struct {
  DryRun         bool
  PrepareStmt    bool
  WithConditions bool
  Context        context.Context
  Logger         logger.Interface
  NowFunc        func() time.Time
}
```

## DryRun

Генерировать `SQL` без выполнения, может быть использован для подготовки или тестирования сгенерированных SQL, например:

```go
// режим новой сессии
stmt := db.Session(&Session{DryRun: true}).First(&user, 1).Statement
stmt.SQL.String() //=> SELECT * FROM `users` WHERE `id` = $1 ORDER BY `id`
stmt.Vars         //=> []interface{}{1}

// глобальный режим DryRun
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{DryRun: true})

// разные БД генерируют разные SQL запросы
stmt := db.Find(&user, 1).Statement
stmt.SQL.String() //=> SELECT * FROM `users` WHERE `id` = $1 // PostgreSQL
stmt.SQL.String() //=> SELECT * FROM `users` WHERE `id` = ?  // MySQL
stmt.Vars         //=> []interface{}{1}
```

## Подготовить

`PreparedStmt` создает подготовленное объекты при выполнении любого SQL и кэширует их для ускорения будущих звонков, например:

```go
// режим непрерывной сессии
tx := db.Session(&Session{PrepareStmt: true})
tx.First(&user, 1)
tx.Find(&users)
tx.Model(&user).Update("Age", 18)

// глобальный режим с подготовленным stmt, все операции создадут готовый stmt и кэширует их для ускорения в будущем
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{PrepareStmt: true})

// Управление подготовленными экземплярами
stmtManger, ok := db.ConnPool.(*PreparedStmtDB)

// Закрытие всех подготовленных экземпляров
stmtManger.Close()

// Подготовленная карта кэша экземпляров
stmtManger.Stmts // map[string]*sql.Stmt

for sql, stmt := range stmtManger.Stmts {
  sql  // подготовленный SQL
  stmt // подготовленный экземпляр statement
}
```

## WithConditions (с условиями)

Поделиться условиями `*gorm.DB` при помощи параметра `WithConditions`, например:

```go
tx := db.Where("name = ?", "jinzhu").Session(&gorm.Session{WithConditions: true})

tx.First(&user)
// SELECT * FROM users WHERE name = "jinzhu" ORDER BY id

tx.First(&user, "id = ?", 10)
// SELECT * FROM users WHERE name = "jinzhu" AND id = 10 ORDER BY id

// Без параметра `WithConditions`
tx2 := db.Where("name = ?", "jinzhu").Session(&gorm.Session{WithConditions: false})
tx2.First(&user)
// SELECT * FROM users ORDER BY id
```

## Контекст

С параметром `Context`, вы можете установить `Context` для следующих операций SQL, например:

```go
timeoutCtx, _ := context.WithTimeout(context.Background(), time.Second)
tx := db.Session(&Session{Context: timeoutCtx})

tx.First(&user) // запрос с контекстом timeoutCtx
tx.Model(&user).Update("role", "admin") // обновление с контекстом timeoutCtx
```

GORM также предоставляет сокращение для `WithContext`, при помощи:

```go
func (db *DB) WithContext(ctx context.Context) *DB {
  return db.Session(&Session{WithConditions: true, Context: ctx})
}
```

## Logger

Gorm позволяет настроить встроенный логгер, используя опцию `Logger`, например:

```go
newLogger := logger.New(log.New(os.Stdout, "\r\n", log.LstdFlags),
              logger.Config{
                SlowThreshold: time.Second,
                LogLevel:      logger.Silent,
                Colorful:      false,
              })
db.Session(&Session{Logger: newLogger})

db.Session(&Session{Logger: logger.Default.LogMode(logger.Silent)})
```

Смотрите [Logger](logger.html) для получения дополнительной информации

## NowFunc

`NowFunc` позволяет изменить функцию, чтобы получить текущее время GORM, например:

```go
db.Session(&Session{
  NowFunc: func() time.Time {
    return time.Now().Local()
  },
})
```

## Отладка

`Debug` это краткий метод изменения `Logger` сессии на режим отладки, вот определение:

```go
func (db *DB) Debug() (tx *DB) {
  return db.Session(&Session{
    WithConditions: true,
    Logger:         db.Logger.LogMode(logger.Info),
  })
}
```
