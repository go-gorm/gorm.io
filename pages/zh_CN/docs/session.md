---
title: 会话
layout: page
---

GORM 提供了 `Session` 方法，这是一个 [`New Session Method`](method_chaining.html)，它允许创建带配置的新建会话模式：

```go
// Session Configuration
type Session struct {
  DryRun                   bool
  PrepareStmt              bool
  NewDB                    bool
  SkipHooks                bool
  SkipDefaultTransaction   bool
  DisableNestedTransaction bool
  AllowGlobalUpdate        bool
  FullSaveAssociations     bool
  QueryFields              bool
  CreateBatchSize          int
  Context                  context.Context
  Logger                   logger.Interface
  NowFunc                  func() time.Time
}
```

## DryRun

DryRun 模式会生成但不执行 `SQL`，可以用于准备或测试生成的 SQL，详情请参考 Session：

```go
// 新建会话模式
stmt := db.Session(&Session{DryRun: true}).First(&user, 1).Statement
stmt.SQL.String() //=> SELECT * FROM `users` WHERE `id` = $1 ORDER BY `id`
stmt.Vars         //=> []interface{}{1}

// 全局 DryRun 模式
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{DryRun: true})

// 不同的数据库生成不同的 SQL
stmt := db.Find(&user, 1).Statement
stmt.SQL.String() //=> SELECT * FROM `users` WHERE `id` = $1 // PostgreSQL
stmt.SQL.String() //=> SELECT * FROM `users` WHERE `id` = ?  // MySQL
stmt.Vars         //=> []interface{}{1}
```

你可以使用下面的代码生成最终的 SQL：

```go
// 注意：SQL 并不总是能安全地执行，GORM 仅将其用于日志，它可能导致会 SQL 注入
db.Dialector.Explain(stmt.SQL.String(), stmt.Vars...)
// SELECT * FROM `users` WHERE `id` = 1
```

## 预编译

`PreparedStmt` 在执行任何 SQL 时都会创建一个 prepared statement 并将其缓存，以提高后续的效率，例如：

```go
// 全局模式，所有 DB 操作都会 创建并缓存预编译语句
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  PrepareStmt: true,
})

// 会话模式
tx := db.Session(&Session{PrepareStmt: true})
tx.First(&user, 1)
tx.Find(&users)
tx.Model(&user).Update("Age", 18)

// returns prepared statements manager
stmtManger, ok := tx.ConnPool.(*PreparedStmtDB)

// 关闭 *当前会话* 的预编译模式
stmtManger.Close()

// 为 *当前会话* 预编译 SQL
stmtManger.PreparedSQL // => []string{}

// 为当前数据库连接池的（所有会话）开启预编译模式
stmtManger.Stmts // map[string]*sql.Stmt

for sql, stmt := range stmtManger.Stmts {
  sql  // 预编译 SQL
  stmt // 预编译模式
  stmt.Close() // 关闭预编译模式
}
```

## NewDB

通过 `NewDB` 选项创建一个不带之前条件的新 DB，例如：

```go
tx := db.Where("name = ?", "jinzhu").Session(&gorm.Session{NewDB: true})

tx.First(&user)
// SELECT * FROM users ORDER BY id LIMIT 1

tx.First(&user, "id = ?", 10)
// SELECT * FROM users WHERE id = 10 ORDER BY id

// 不带 `NewDB` 选项
tx2 := db.Where("name = ?", "jinzhu").Session(&gorm.Session{})
tx2.First(&user)
// SELECT * FROM users WHERE name = "jinzhu" ORDER BY id
```

## 跳过钩子

如果您想跳过 `钩子` 方法，您可以使用 `SkipHooks` 会话模式，例如：

```go
DB.Session(&gorm.Session{SkipHooks: true}).Create(&user)

DB.Session(&gorm.Session{SkipHooks: true}).Create(&users)

DB.Session(&gorm.Session{SkipHooks: true}).CreateInBatches(users, 100)

DB.Session(&gorm.Session{SkipHooks: true}).Find(&user)

DB.Session(&gorm.Session{SkipHooks: true}).Delete(&user)

DB.Session(&gorm.Session{SkipHooks: true}).Model(User{}).Where("age > ?", 18).Updates(&user)
```

## DisableNestedTransaction

When using `Transaction` method inside a db transaction, GORM will use `SavePoint(savedPointName)`, `RollbackTo(savedPointName)` to give you the nested transaction support, you could disable it by using the `DisableNestedTransaction` option, for example:

```go
db.Session(&gorm.Session{
  DisableNestedTransaction: true,
}).CreateInBatches(&users, 100)
```

## AllowGlobalUpdate

GORM doesn't allow global update/delete by default, will return `ErrMissingWhereClause` error, you can set this option to true to enable it, for example:

```go
db.Session(&gorm.Session{
  AllowGlobalUpdate: true,
}).Model(&User{}).Update("name", "jinzhu")
// UPDATE users SET `name` = "jinzhu"
```

## FullSaveAssociations

GORM will auto-save associations and its reference using [Upsert](create.html#upsert) when creating/updating a record, if you want to update associations's data, you should use the `FullSaveAssociations` mode, e.g:

```go
db.Session(&gorm.Session{FullSaveAssociations: true}).Updates(&user)
// ...
// INSERT INTO "addresses" (address1) VALUES ("Billing Address - Address 1"), ("Shipping Address - Address 1") ON DUPLICATE KEY SET address1=VALUES(address1);
// INSERT INTO "users" (name,billing_address_id,shipping_address_id) VALUES ("jinzhu", 1, 2);
// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu@example.com"), (111, "jinzhu-2@example.com") ON DUPLICATE KEY SET email=VALUES(email);
// ...
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
  return db.Session(&Session{Context: ctx})
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
    Logger:         db.Logger.LogMode(logger.Info),
  })
}
```

## QueryFields

Select by fields

```go
db.Session(&gorm.Session{QueryFields: true}).Find(&user)
// SELECT `users`.`name`, `users`.`age`, ... FROM `users` // with this option
// SELECT * FROM `users` // without this option
```

## CreateBatchSize

Default batch size

```go
users = [5000]User{{Name: "jinzhu", Pets: []Pet{pet1, pet2, pet3}}...}

db.Session(&gorm.Session{CreateBatchSize: 1000}).Create(&users)
// INSERT INTO users xxx (5 batches)
// INSERT INTO pets xxx (15 batches)
```
