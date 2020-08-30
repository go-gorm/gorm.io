---
title: Generic database interface sql.DB
layout: page
---

GORM provides the method `DB` which returns a generic database interface [\*sql.DB](https://pkg.go.dev/database/sql#DB) from the current `*gorm.DB`

```go
// Get generic database object sql.DB to use its functions
sqlDB, err := db.DB()

// Ping
sqlDB.Ping()

// Close
sqlDB.Close()

// Returns database statistics
sqlDB.Stats()
```

{% note warn %}
**NOTE** If the underlying database connection is not a `*sql.DB`, like in a transaction, it will returns error
{% endnote %}

## Connection Pool

```go
// Get generic database object sql.DB to use its functions
sqlDB, err := db.DB()

// SetMaxIdleConns sets the maximum number of connections in the idle connection pool.
sqlDB.SetMaxIdleConns(10)

// SetMaxOpenConns sets the maximum number of open connections to the database.
sqlDB.SetMaxOpenConns(100)

// SetConnMaxLifetime sets the maximum amount of time a connection may be reused.
sqlDB.SetConnMaxLifetime(time.Hour)
```
