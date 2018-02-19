---
title: Generic database interface sql.DB
layout: page
---

GORM provides method `DB` which returns generic database interface [*sql.DB](http://golang.org/pkg/database/sql/#DB) from current `*gorm.DB` connection

```go
// Get generic database object sql.DB to use its functions
db.DB()

// Ping
db.DB().Ping()
```

**NOTE** If the underlying database connection is not a `*sql.DB`, like in a transaction, it will returns nil

## Connection Pool

```go
// SetMaxIdleConns sets the maximum number of connections in the idle connection pool.
db.DB().SetMaxIdleConns(10)

// SetMaxOpenConns sets the maximum number of open connections to the database.
db.DB().SetMaxOpenConns(100)

// SetConnMaxLifetime sets the maximum amount of time a connection may be reused.
db.DB().SetConnMaxLifetime(time.Hour)
```
