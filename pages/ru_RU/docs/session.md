---
title: Сессия
layout: страница
---

GORM предоставляет методы `Session`, которые являются [`Методами новой сессии`](method_chaining.html), и позволяют создавать новый режим сеанса с настройками:

```go
// Session Configuration
type Session struct {
  DryRun            bool
  PrepareStmt       bool
  WithConditions    bool
  AllowGlobalUpdate bool
  Context           context.Context
  Logger            logger.Interface
  NowFunc           func() time.Time
}
```

## DryRun

Генерировать `SQL` без выполнения, может быть использован для подготовки или тестирования сгенерированных SQL, например:

```go
// session mode
stmt := db.Session(&Session{DryRun: true}).First(&user, 1).Statement
stmt.SQL.String() //=> SELECT * FROM `users` WHERE `id` = $1 ORDER BY `id`
stmt.Vars         //=> []interface{}{1}

// globally mode with DryRun
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{DryRun: true})

// different databases generate different SQL
stmt := db.Find(&user, 1).Statement
stmt.SQL.String() //=> SELECT * FROM `users` WHERE `id` = $1 // PostgreSQL
stmt.SQL.String() //=> SELECT * FROM `users` WHERE `id` = ?  // MySQL
stmt.Vars         //=> []interface{}{1}
```

## Подготовить

`PreparedStmt` создает подготовленное объекты при выполнении любого SQL и кэширует их для ускорения будущих звонков, например:

```go
// globally mode, all DB operations will create prepared stmt and cache them
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  PrepareStmt: true,
})

// session mode
tx := db.Session(&Session{PrepareStmt: true})
tx.First(&user, 1)
tx.Find(&users)
tx.Model(&user).Update("Age", 18)

// returns prepared statements manager
stmtManger, ok := tx.ConnPool.(*PreparedStmtDB)

// close prepared statements for *current session*
stmtManger.Close()

// prepared SQL for *current session*
stmtManger.PreparedSQL // => []string{}

// prepared statements for current database connection pool (all sessions)
stmtManger.Stmts // map[string]*sql.Stmt

for sql, stmt := range stmtManger.Stmts {
  sql  // prepared SQL
  stmt // prepared statement
  stmt.Close() // close the prepared statement
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

## AllowGlobalUpdate

GORM doesn't allow global update/delete by default, will return `ErrMissingWhereClause` error, you can set this option to true to enable it, for example:

```go
DB.Session(&gorm.Session{
  AllowGlobalUpdate: true,
}).Model(&User{}).Update("name", "jinzhu")
// UPDATE users SET `name` = "jinzhu"
```

## Context

With the `Context` option, you can set the `Context` for following SQL operations, for example:

```go
timeoutCtx, _ := context.WithTimeout(context.Background(), time.Second)
tx := db.Session(&Session{Context: timeoutCtx})

tx.First(&user) // query with context timeoutCtx
tx.Model(&user).Update("role", "admin") // update with context timeoutCtx
```

GORM also provides shortcut method `WithContext`,  here is the definition:

```go
func (db *DB) WithContext(ctx context.Context) *DB {
  return db.Session(&Session{WithConditions: true, Context: ctx})
}
```

## Logger

Gorm allows customize built-in logger with the `Logger` option, for example:

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

Checkout [Logger](logger.html) for more details

## NowFunc

`NowFunc` allows change the function to get current time of GORM, for example:

```go
db.Session(&Session{
  NowFunc: func() time.Time {
    return time.Now().Local()
  },
})
```

## Debug

`Debug` is a shortcut method to change session's `Logger` to debug mode,  here is the definition:

```go
func (db *DB) Debug() (tx *DB) {
  return db.Session(&Session{
    WithConditions: true,
    Logger:         db.Logger.LogMode(logger.Info),
  })
}
```
