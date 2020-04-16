---
title: Interfaccia database generica sql.DB
layout: page
---

GORM fornisce il metodo `DB` che restituisce un'interfaccia generica del database [*sql.DB](http://golang.org/pkg/database/sql/#DB) dalla connessione corrente `*gorm.DB`

```go
// Get generic database object sql.DB to use its functions
db.DB()

// Ping
db.DB().Ping()
```

**NOTA** Se la connessione al database sottostante non è un `*sql.DB`, come in una transazione, restituirà `nil`

## Gruppo di connessioni

```go
// SetMaxIdleConns sets the maximum number of connections in the idle connection pool.
db.DB().SetMaxIdleConns(10)

// SetMaxOpenConns sets the maximum number of open connections to the database.
db.DB().SetMaxOpenConns(100)

// SetConnMaxLifetime sets the maximum amount of time a connection may be reused.
db.DB().SetConnMaxLifetime(time.Hour)
```