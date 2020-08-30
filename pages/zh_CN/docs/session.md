---
title: 会话
layout: page
---

GORM 提供了 `Session` 方法，这是一个 [`New Session Method`](method_chaining.html)，它允许创建带配置的新建会话模式：

```go
// Session 配置
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

DarRun 模式会生成但不执行 `SQL`，可以用于准备或测试生成的 SQL，详情请参考 Session：

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

## WithConditions

`WithCondition` 会共享 `*gorm.DB` 的条件，例如：

```go
tx := db.Where("name = ?", "jinzhu").Session(&gorm.Session{WithConditions: true})

tx.First(&user)
// SELECT * FROM users WHERE name = "jinzhu" ORDER BY id

tx.First(&user, "id = ?", 10)
// SELECT * FROM users WHERE name = "jinzhu" AND id = 10 ORDER BY id

// 不共享 `WithConditions`
tx2 := db.Where("name = ?", "jinzhu").Session(&gorm.Session{WithConditions: false})
tx2.First(&user)
// SELECT * FROM users ORDER BY id
```

## AllowGlobalUpdate

默认情况下，GORM 不允许全局 update/delete，它会返回 `ErrMissingWhereClause` 错误，你可以将该选项置为 true 以允许全局操作，例如：

```go
DB.Session(&gorm.Session{
  AllowGlobalUpdate: true,
}).Model(&User{}).Update("name", "jinzhu")
// UPDATE users SET `name` = "jinzhu"
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
  return db.Session(&Session{WithConditions: true, Context: ctx})
}
```

## Logger

Gorm 允许使用 `Logger` 选项自定义内建 Logger，例如：

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

查看 [Logger](logger.html) 获取详情

## NowFunc

`NowFunc` 允许改变 GORM 获取当前时间的实现，例如：

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
    WithConditions: true,
    Logger:         db.Logger.LogMode(logger.Info),
  })
}
```
