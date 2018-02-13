# Generic database interface sql.DB

Get generic database interface [*sql.DB](http://golang.org/pkg/database/sql/#DB) from `*gorm.DB` connection

```go
// Get generic database object `*sql.DB` to use its functions
db.DB()

// Ping
db.DB().Ping()
```

## Connection Pool

```go
db.DB().SetMaxIdleConns(10)
db.DB().SetMaxOpenConns(100)
```
