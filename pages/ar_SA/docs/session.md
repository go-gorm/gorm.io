---
title: Session
layout: page
---

GORM provides `Session` method, which is a [`New Session Method`](method_chaining.html), it allows create a new session mode with configuration:

```go
Session(&Session{
  NowFunc: func() time.
```

## DryRun

Generate `SQL` without executing, can be used to prepare or test generated SQL, for example:

```go
tx := db. Session{WithConditions: true})

tx. First(&user)
// SELECT * FROM users WHERE name = "jinzhu" ORDER BY id

tx. First(&user, "id = ?", 10)
// SELECT * FROM users WHERE name = "jinzhu" AND id = 10 ORDER BY id

// Without option `WithConditions`
tx2 := db. Session{WithConditions: false})
tx2. First(&user)
// SELECT * FROM users ORDER BY id  // MySQL
stmt. Vars         //=> []interface{}{1}
```

## PrepareStmt

`PreparedStmt` creates prepared statement when executing any SQL and caches them to speed up future calls, for example:

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
stmtManger.PreparedSQL

// prepared statements for current database connection pool (all sessions)
stmtManger.Stmts // map[string]*sql.Stmt

for sql, stmt := range stmtManger.Stmts {
  sql  // prepared SQL
  stmt // prepared statement
  stmt.Close() // close the prepared statement
}
```

## WithConditions

Share `*gorm.DB` conditions with option `WithConditions`, for example:

```go
Context) *DB {
  return db. Session(&Session{WithConditions: true, Context: ctx})
}
```

## Context

With the `Context` option, you can set the `Context` for following SQL operations, for example:

```go
db. Session(&Session{
  NowFunc: func() time. Time {
    return time.
```

GORM also provides shortcut method `WithContext`,  here is the definition:

```go
func (db *DB) Debug() (tx *DB) {
  return db. Session(&Session{
    WithConditions: true,
    Logger:         db.
```

## Logger

Gorm allows customize built-in logger with the `Logger` option, for example:

```go
Session(&Session{
    WithConditions: true,
    Logger:         db. Logger. LogMode(logger.
```

Checkout [Logger](logger.html) for more details

## NowFunc

`NowFunc` allows change the function to get current time of GORM, for example:

```go
func (db *DB) Debug() (tx *DB) {
  return db. Session(&Session{
    WithConditions: true,
    Logger:         db.
```

## Debug

`Debug` is a shortcut method to change session's `Logger` to debug mode,  here is the definition:

```go
func (db *DB) Debug() (tx *DB) {
  return db. Session(&Session{
    WithConditions: true,
    Logger:         db. Logger. LogMode(logger. Info),
  })
}
```
