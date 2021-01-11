---
title: 会话
layout: page
---

GORM provides `Session` method, which is a [`New Session Method`](method_chaining.html), it allows to create a new session mode with configuration:

```go
// Session 配置
type Session struct {
  DryRun                 bool
  PrepareStmt            bool
  NewDB                  bool
  SkipHooks              bool
  SkipDefaultTransaction bool
  AllowGlobalUpdate      bool
  FullSaveAssociations   bool
  Context                context.Context
  Logger                 logger.Interface
  NowFunc                func() time.Time
}
```

## DryRun

Generates `SQL` without executing. It can be used to prepare or test generated SQL, for example:

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

To generate the final SQL, you could use following code:

```go
// NOTE: the SQL is not always safe to execute, GORM only uses it for logs, it might cause SQL injection
db.Dialector.Explain(stmt.SQL.String(), stmt.Vars...)
// SELECT * FROM `users` WHERE `id` = 1
```

## 预编译

`PreparedStmt` creates prepared statements when executing any SQL and caches them to speed up future calls, for example:

```go
// globally mode, all DB operations will create prepared statements and cache them
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

## 禁用嵌套事务

When using `Transaction` method inside a DB transaction, GORM will use `SavePoint(savedPointName)`, `RollbackTo(savedPointName)` to give you the nested transaction support. You can disable it by using the `DisableNestedTransaction` option, for example:

```go
db.Session(&gorm.Session{
  DisableNestedTransaction: true,
}).CreateInBatches(&users, 100)
```

## AllowGlobalUpdate

GORM doesn't allow global update/delete by default, will return `ErrMissingWhereClause` error. You can set this option to true to enable it, for example:

```go
db.Session(&gorm.Session{
  AllowGlobalUpdate: true,
}).Model(&User{}).Update("name", "jinzhu")
// UPDATE users SET `name` = "jinzhu"
```

## FullSaveAssociations

GORM will auto-save associations and its reference using [Upsert](create.html#upsert) when creating/updating a record. If you want to update associations' data, you should use the `FullSaveAssociations` mode, for example:

```go
db.Session(&gorm.Session{FullSaveAssociations: true}).Updates(&user)
// ...
// INSERT INTO "addresses" (address1) VALUES ("Billing Address - Address 1"), ("Shipping Address - Address 1") ON DUPLICATE KEY SET address1=VALUES(address1);
// INSERT INTO "users" (name,billing_address_id,shipping_address_id) VALUES ("jinzhu", 1, 2);
// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu@example.com"), (111, "jinzhu-2@example.com") ON DUPLICATE KEY SET email=VALUES(email);
// ...
```

## Context

通过 `Context` 选项，您可以传入 `Context` 来追踪 SQL 操作，例如：

```go
timeoutCtx, _ := context.WithTimeout(context.Background(), time.Second)
tx := db.Session(&Session{Context: timeoutCtx})

tx.First(&user) // 带 timeoutCtx 的查询
tx.Model(&user).Update("role", "admin") // 带 timeoutCtx 的更新
```

GORM 也提供了快捷调用方法 `WithContext`，其实现如下：

```go
func (db *DB) WithContext(ctx context.Context) *DB {
  return db.Session(&Session{Context: ctx})
}
```

## Logger

Gorm allows customizing built-in logger with the `Logger` option, for example:

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

Checkout [Logger](logger.html) for more details.

## NowFunc

`NowFunc` allows changing the function to get current time of GORM, for example:

```go
db.Session(&Session{
  NowFunc: func() time.Time {
    return time.Now().Local()
  },
})
```

## Debug

`Debug` 只是将会话的 `Logger` 修改为调试模式的快捷方法，其实现如下：

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
// SELECT `users`.`name`, `users`.`age`, ... FROM `users` // 带该选项
// SELECT * FROM `users` // 不带该选项
```

## CreateBatchSize

Default batch size

```go
users = [5000]User{{Name: "jinzhu", Pets: []Pet{pet1, pet2, pet3}}...}

db.Session(&gorm.Session{CreateBatchSize: 1000}).Create(&users)
// INSERT INTO users xxx (需 5 次)
// INSERT INTO pets xxx (需 15 次)
```
